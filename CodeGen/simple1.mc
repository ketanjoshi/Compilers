goto 2;
print (Input three small numbers );
read M[11];
read M[12];
read M[13];
print (Input data are ) M[11] ( ) M[12] ( ) M[13] (\n)  ;
load R1 M[11];
sub R1 R1 5;
store M[0] R1;
load R4 M[0];
store M[11] R4;
load R1 M[12];
add R1 R1 3;
store M[0] R1;
load R4 M[0];
store M[12] R4;
load R1 M[13];
add R1 R1 2;
store M[0] R1;
load R4 M[0];
store M[13] R4;
load R1 M[11];
add R1 R1 M[12];
store M[0] R1;
load R4 M[0];
store M[14] R4;
print (Modified input are ) M[11] ( ) M[12] ( ) M[13] (\n)  ;
print (Final result is ) M[14] (\n);
load R0 99;