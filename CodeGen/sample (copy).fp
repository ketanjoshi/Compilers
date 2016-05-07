CONSTANTS

FUNCTIONS
{ factorial val return retval
    { if {< val 0}
      then {= retval -1} 
      else {= retval 1}
           { while {> val 0}
              {= retval {* retval val}}
              {= val {- val 1}}
           }
    }
}

MAIN
{read x}
{= f {factorial x}}
{print (Factorial of) x (is) f (\n)}

