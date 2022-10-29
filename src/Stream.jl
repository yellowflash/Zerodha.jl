module Stream
    export Command, Quote, parse_quote
    using StructTypes

    DEPTH = 184
    QUOTE = 44
    LTP_ONLY = 8
    INDEX_QUOTE = 28
    INDEX_DEPTH = 32

    struct Command
        c:: String
        v
    end

    struct Depth
        price:: Float64
        quantity:: Int32
        orders:: Int32
    end

    struct MarketDepth
        bid:: Array{Depth}
        ask:: Array{Depth}
    end

    struct FullQuote
        instrument:: Int32
        ltp:: Float64
        ltq:: Int32
        day_volume:: Int32
        buy_quantity:: Int32
        sell_quantity:: Int32

        day_open:: Float64
        day_high:: Float64
        day_low:: Float64
        day_close:: Float64

        timestamp:: Int32
        oi:: Int32
        day_high_oi:: Int32
        day_low_oi:: Int32
        exchange_timestamp:: Int32

        market_depth:: MarketDepth
    end

    struct Quote
        instrument:: Int32
        ltp:: Float64
        ltq:: Int32
        day_volume:: Int32
        buy_quantity:: Int32
        sell_quantity:: Int32

        day_open:: Float64
        day_high:: Float64
        day_low:: Float64
        day_close:: Float64
    end

    struct LastTradedPrice
        instrument:: Int32
        ltp:: Float64
    end

    struct IndexQuote
        instrument:: Int32
        ltp:: Float64

        day_high:: Float64
        day_low:: Float64
        day_open:: Float64
        day_close:: Float64

        price_change:: Float64
    end

    struct IndexFull
        instrument:: Int32
        ltp:: Float64

        day_high:: Float64
        day_low:: Float64
        day_open:: Float64
        day_close:: Float64

        price_change:: Float64

        exchange_timestamp:: Int32
    end

    Tick = Union{FullQuote, Quote, LastTradedPrice, IndexQuote, IndexFull}

    StructTypes.StructType(::Command) = StructTypes.Struct()

    read_price!(buffer):: Float64 = read(buffer, Int32) / 100.0

    function read_depth_entry!(buffer)
        quantity = read(buffer, Int32)
        price = read_price!(buffer)
        orders = read(buffer, Int32)
        skip = read(buffer, Int16)

        return Depth(price, quantity, orders)
    end

    function read_market_depth!(buffer) 
        bids = []
        asks = []
        for i in 1:5
            push!(bids, read_depth_entry!(buffer))
        end
        for i in 1:5
            push!(asks, read_depth_entry!(buffer))
        end
        MarketDepth(bids, asks)
    end

    function parse_quote(buffer:: IOBuffer):: Tick
        packets = read(buffer, Int16)
        result = []
        for i in 0:packets
            length == read(buffer, Int16)
            if length == DEPTH
                push!(result, FullQuote(
                    read(buffer, Int32),
                    read_price(buffer),
                    read(buffer, Int32),
                    read(buffer, Int32),
                    read(buffer, Int32),
                    read(buffer, Int32),
                    read_price!(buffer),
                    read_price!(buffer),
                    read_price!(buffer),
                    read_price!(buffer),
                    read(buffer, Int32),
                    read(buffer, Int32),
                    read(buffer, Int32),
                    read(buffer, Int32),
                    read(buffer, Int32),
                    read_market_depth(buffer, Int32)))
            elseif length == QUOTE
                push!(result, Quote(
                    read(buffer, Int32),
                    read_price(buffer),
                    read(buffer, Int32),
                    read(buffer, Int32),
                    read(buffer, Int32),
                    read(buffer, Int32),
                    read_price!(buffer),
                    read_price!(buffer),
                    read_price!(buffer),
                    read_price!(buffer)))
            elseif length == LTP_ONLY
                push!(result, LastTradedPrice(
                    read(buffer, Int32),
                    read_price(buffer)))
            elseif length == IndexFull
                push!(result, IndexFull(
                    read(buffer, Int32),
                    read_price(buffer),
                    read_price!(buffer),
                    read_price!(buffer),
                    read_price!(buffer),
                    read_price!(buffer),
                    read_price!(buffer),
                    read(buffer, Int32)))
            elseif length == IndexQuote
                push!(result, IndexQuote(
                    read(buffer, Int32),
                    read_price(buffer),
                    read_price!(buffer),
                    read_price!(buffer),
                    read_price!(buffer),
                    read_price!(buffer),
                    read_price!(buffer)))
            else
                throw(ErrorException("Invalid length " * length))
            end
        end
        return result
    end
end