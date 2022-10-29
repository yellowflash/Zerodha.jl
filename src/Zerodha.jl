module Zerodha
    import HTTP
    import JSON3
    using SHA
    base_url = "https://api.kite.trade"

    include("./Response.jl")
    include("./Types.jl")
    include("./Stream.jl")

    module Request 
        using ..Types
        struct MarketOrder
            variety:: Variety
            trading_symbol:: String
            exchange:: Exchange
            transaction_type:: TransactionType
            quantity:: Int64
            product:: Product
            validity:: OrderValidity
            tag:: Union{String, Nothing}
        end

        struct LimitOrder
            variety:: Variety
            trading_symbol:: String
            exchange:: Exchange
            transaction_type:: TransactionType
            quantity:: Int64
            product:: Product
            validity:: OrderValidity
            price:: Float64
            tag:: Union{String, Nothing}
        end

        struct StopLossMarketOrder
            variety:: Variety
            trading_symbol:: String
            exchange:: Exchange
            transaction_type:: TransactionType
            quantity:: Int64
            product:: Product
            validity:: OrderValidity
            trigger_price:: Float64
            tag:: Union{String, Nothing}
        end

        struct StopLossOrder
            variety:: Variety
            trading_symbol:: String
            exchange:: Exchange
            transaction_type:: TransactionType
            quantity:: Int64
            product:: Product
            validity:: OrderValidity
            price:: Float64
            trigger_price:: Float64
            tag:: Union{String, Nothing}
        end
    end

    struct Session
        base_url:: String
        api_key:: String
        access_token:: String
    end

    function request(session:: Session, type:: String, path:: String, :: Type{T}; body = Dict()) where {T}
        response = HTTP.request(
            type,
            session.base_url * path,
            base_url * path,
            headers = Dict(
                "Content-Type" => "application/x-www-form-urlencoded",
                "X-Kite-Version" => "3",
                "Authorization" => "token " * session.api_key * ":" * session.access_token),
            body = body)

        return response.body |> String |> (b -> JSON3.read(b, Response.Wrapper{T}).data)
    end

    function session(api_key:: String, api_secret:: String, request_token:: String)
        response = HTTP.request(
            "POST",
            "$base_url/session/token",
            body = HTTP.escapeuri(Dict(
                "api_key" => api_key,
                "request_token" => request_token,
                "checksum" =>  (api_key * request_token * api_secret) |> sha256 |> bytes2hex)),
            headers = Dict(
                "X-Kite-Version" => "3",
                "Content-Type" => "application/x-www-form-urlencoded"))
        body = response.body |> String |> JSON3.read
        return Session(base_url, api_key, body.data.access_token)
    end

    orders(session:: Session) = request(session, "GET", "/orders", Array{Response.Order})
    portfolio(session:: Session) = request(session, "GET", "/portfolio/holdings", Array{Response.Holding})


    validity_param(::Types.DayValidity) = Dict("validity" => "DAY")
    validity_param(::Types.ImmediateOrCancel) = Dict("validity" => "IOC")
    validity_param(ttl::Types.TTL) = Dict("validity" => "TTL", "validity_ttl" => ttl.ttl)

    tag_param(tag:: String) = Dict("tag" => tag)
    tag_param(::Nothing) = Dict()

    function place_order(session:: Session, order:: Request.MarketOrder)
        response = request(
            session, 
            "POST", 
            "/orders/$(String(order.variety))",
            Response.PlacedOrder,
            body = merge(Dict(
                    "order_type" => "MARKET",
                    "tradingsymbol" => order.trading_symbol,
                    "exchange" => String(order.exchange),
                    "transaction_type" => String(order.transaction_type),
                    "quantity" => order.quantity,
                    "product" => String(order.product)), 
                    validity_param(order.validity), 
                    tag_param(order.tag)))
        return Types.OrderIdentifier(order.variety, response.order_id)
    end

    function place_order(session:: Session, order:: Request.LimitOrder)
        response = request(
            session, 
            "POST", 
            "/orders/$(String(order.variety))",
            Response.PlacedOrder,
            body = merge(Dict(
                    "order_type" => "LIMIT",
                    "tradingsymbol" => order.trading_symbol,
                    "exchange" => order.exchange,
                    "transaction_type" => order.transaction_type,
                    "quantity" => order.quantity,
                    "product" => order.product,
                    "price" => order.price), 
                    validity_param(order.validity), 
                    tag_param(order.tag)))
        return Types.OrderIdentifier(order.variety, response.order_id)
    end

    function place_order(session:: Session, order:: Request.StopLossMarketOrder)
        response = request(
            session, 
            "POST", 
            "/orders/$(String(order.variety))",
            Response.PlacedOrder,
            body = merge(Dict(
                    "order_type" => "SL-M",
                    "tradingsymbol" => order.trading_symbol,
                    "exchange" => order.exchange,
                    "transaction_type" => String(order.transaction_type),
                    "quantity" => order.quantity,
                    "product" => order.product,
                    "trigger_price" => order.trigger_price), 
                    validity_param(order.validity), 
                    tag_param(order.tag)))
        return Types.OrderIdentifier(order.variety, response.order_id)
    end

    function place_order(session:: Session, order:: Request.StopLossOrder)
        response = request(
            session, 
            "POST", 
            "/orders/$(String(order.variety))",
            Response.PlacedOrder,
            body = merge(Dict(
                    "order_type" => "SL",
                    "tradingsymbol" => order.trading_symbol,
                    "exchange" => order.exchange,
                    "transaction_type" => String(order.transaction_type),
                    "quantity" => order.quantity,
                    "product" => order.product,
                    "price" => order.price,
                    "trigger_price" => order.trigger_price), 
                    validity_param(order.validity), 
                    tag_param(order.tag)))
        return Types.OrderIdentifier(order.variety, response.order_id)
    end

    function cancel_order(session:: Session, order:: Types.OrderIdentifier) 
        response = request(session, "DELETE", "/orders/$(String(order.variety))/$(order.order_id)", Response.PlacedOrder)
        return Types.OrderIdentifier(order.variety, response.order_id)
    end

    module Live
        import ..Session
        import ..Types
        using ..Stream

        import JSON3
        using HTTP.WebSockets

        websocket_url = "wss://ws.kite.trade"

        function ticks(session:: Session, instruments:: Array{Int32}, mode:: Types.Mode) 
            return Channel(Inf) do ch
                WebSockets.open("$(websocket_url)?api_key=$(session.api_key)&access_token=$(session.access_token)") do ws
                    send(ws, JSON3.write(Command("subscribe", instruments)))
                    send(ws, JSON3.write(Command("mode", [String(mode), instruments])))
                    while true 
                        message = receive(ws)
                        if message isa Array{Int8} && length(message) >= 2
                            buffer = IOBuffer(message)
                            send!(ch, parse(buffer))
                        else 
                            println("Skipping" * String(message))
                        end
                    end
                end
            end
        end
     
    end
end