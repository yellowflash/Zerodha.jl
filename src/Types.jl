module Types
    export Variety, Exchange, TransactionType, Product, OrderValidity, DayValidity, ImmediateOrCancel, TTL, NSE, OrderIdentifier

    @enum Product CNC NRML MIS
    @enum Exchange NSE BSE NFO CDS BCD MCX
    @enum TransactionType Buy Sell

    struct Regular end
    struct AMO end
    struct CO end
    struct Iceberg end

    Variety = Union{Regular, AMO, CO, Iceberg}

    Base.String(::Regular) = "regular"
    Base.String(::AMO) = "amo"
    Base.String(::CO) = "co"
    Base.String(::Iceberg) = "iceberg" 

    Base.String(type::TransactionType) = string(type)
    Base.String(type::Exchange) = string(type)
    Base.String(type::Product) = string(type)

    struct DayValidity end
    struct ImmediateOrCancel end
    struct TTL
        ttl:: Int32
    end

    OrderValidity = Union{DayValidity, ImmediateOrCancel, TTL}

    struct OrderIdentifier
        type:: Variety
        order_id:: String
    end

    @enum Mode LTP, QUOTE, FULL

    function Base.String(mode:: Mode) 
        if mode == LTP
            return "ltp"
        else if mode == QUOTE
            return "quote"
        else
            return "full"
        end
    end
end