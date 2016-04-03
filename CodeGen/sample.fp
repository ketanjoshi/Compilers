CONSTANTS


FUNCTIONS
{fun n return p
	{= p 1}
}
{ factorial val return retval
	{= retval {* retval val}}
	{= val {- val 1}}
}

MAIN
{read x}
{= f {factorial x}}
{print (Factorial of) x (is) f}
