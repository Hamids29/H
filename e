
State Market Share % :=
VAR CurrState =
    SELECTEDVALUE ( DimUCN[State] )
VAR CurrYear =
    SELECTEDVALUE ( DimYear[Year] )
RETURN
CALCULATE (
    [Market Share %],
    -- remove the UCN selection so clicking a bubble doesn't change this
    REMOVEFILTERS ( DimUCN[UCN] ),
    -- keep the state + year we were in
    KEEPFILTERS ( DimUCN[State] = CurrState ),
    KEEPFILTERS ( DimYear[Year] = CurrYear )
)
