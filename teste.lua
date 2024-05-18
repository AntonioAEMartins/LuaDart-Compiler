
function fatorial(n)
    if n == 0 then
      return 1
    else
      return n * fatorial(n - 1)
    end
  end
  
local resultado
resultado = fatorial(5)
  
print(resultado)
