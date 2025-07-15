(function_declaration name: (_) @ancestor.name) @ancestor

(assignment_statement
  (variable_list name: (_) @ancestor.name)
  (expression_list value: (function_definition) @ancestor)
)
