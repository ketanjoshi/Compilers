CONSTANTS


FUNCTIONS
{ fun n return p
	{= p 1}
}
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
{read x y}
{= f {factorial x}}
{print (Factorial of) 1 x (is) f}
