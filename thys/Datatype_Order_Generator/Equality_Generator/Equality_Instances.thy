subsection \<open>Defining Equality-Functions for Common Types\<close>

theory Equality_Instances
imports
  Equality_Generator
begin

text \<open>For all of the following types, we register equality-functions.
  @{type int}, @{type nat}, @{type char}, @{type bool}, @{type unit}, @{type sum}, @{type option}, @{type list},
  and @{type prod}. For types without type parameters, we use plain @{term "op ="}, and for the 
  others we use generated ones. These functions will be essential, when the generator is later on
  invoked on types, which in their definition use one these types.\<close>

derive (eq) equality int nat char bool unit
derive equality sum list prod option

end