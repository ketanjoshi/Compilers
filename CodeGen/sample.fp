CONSTANTS
{conststr (onst1)}

FUNCTIONS

MAIN

{ if {< val 0}
      then {= retval -1} 
      else {= retval 1}
           { while {> val retval}
				{= retval {* retval val}}
				{= val {- val 1}}
           }
}

{read val x}