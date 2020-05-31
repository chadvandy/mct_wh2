--[[for n in pairs(_G) do
    if is_function(n) then
        out("Found function: "..n.."()")
    else
        out("Found variable: "..n)
    end
end

for n in pairs(core:get_env()) do
    if is_function(n) then
        out("Found function: "..n.."()")
    else
        out("Found variable: "..n)
    end
end]]