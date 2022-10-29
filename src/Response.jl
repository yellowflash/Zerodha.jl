module Response 
    import StructTypes

    struct Order
        placed_by:: String
        order_id:: String
        exchange_order_id:: String
        parent_order_id:: Union{String, Nothing}
        status:: String
        status_message:: Union{String, Nothing}
        status_message_raw:: Union{String, Nothing}
        order_timestamp:: String
        exchange_update_timestamp:: Union{String, Nothing}
        exchange_timestamp:: Union{String, Nothing}
        variety:: String
        exchange:: String
        tradingsymbol:: String
        instrument_token:: Int64
        order_type:: String
        transaction_type:: String
        validity:: String
        product:: String
        quantity:: Int64
        disclosed_quantity:: Union{Int64, Nothing}
        price:: Float64
        trigger_price:: Float64
        average_price:: Float64
        filled_quantity:: Int64
        pending_quantity:: Int64
        cancelled_quantity:: Int64
        market_protection:: Int64
        meta:: Dict{String, Any}
        tag:: Union{String, Nothing}
        guid:: String
    end

    struct Holding
        tradingsymbol:: String
        exchange:: String
        instrument_token:: Int64
        isin:: String
        product:: String
        price:: Float64
        quantity:: Int64
        used_quantity:: Int64
        t1_quantity:: Int64
        realised_quantity:: Int64
        authorised_quantity:: Int64
        authorised_date:: String
        opening_quantity:: Int64
        collateral_quantity:: Int64
        collateral_type:: String
        discrepancy:: Bool
        average_price:: Float64
        last_price:: Float64
        close_price:: Float64
        pnl:: Float64
        day_change:: Float64
        day_change_percentage:: Float64
    end

    struct PlacedOrder
        order_id:: String
    end

    struct Wrapper{T}
        data:: T
    end

    StructTypes.StructType(::Order) = StructTypes.Struct()
    StructTypes.StructType(::Wrapper{T}) where {T} = StructTypes.Struct()

end