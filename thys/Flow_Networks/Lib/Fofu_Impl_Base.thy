theory Fofu_Impl_Base
imports 
  Fofu_Abs_Base
  "../../Refine_Imperative_HOL/IICF/IICF"
  "../../Refine_Imperative_HOL/Sepref_ICF_Bindings"
  "~~/src/HOL/Library/Rewrite"
begin
  hide_type (open) List_Seg.node

  interpretation Refine_Monadic_Syntax .
end
