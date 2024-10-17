Interpreter.eval(
  {:program,
   [
     {:open_operation, "io"},
     {:open_operation, "math"},
     {:function_declaration, "main", [],
      {:block,
       [
         {:function_call_operation, "println",
          [{:function_call_operation, "sqrt", [integer_literal: 64]}]}
       ]}}
   ]}
)
