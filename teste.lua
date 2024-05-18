
-- Type mismatch
function ok(x)
    return x
end

function main()
    local y = ok("x")

    print(y + 1)
end

main()


