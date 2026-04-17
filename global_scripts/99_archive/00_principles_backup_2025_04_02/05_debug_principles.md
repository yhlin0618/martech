# Debugging Principles

## 1. Function Integrity

### Function Testing

Every R function must be tested to ensure it can be executed in a proper R environment:

- **✅ DO:** Test each function with valid inputs before integration
- **✅ DO:** Ensure function definitions are complete (including opening and closing brackets)
- **❌ NEVER:** Leave incomplete function definitions in production code
- **✅ DO:** Use proper error handling with `tryCatch` blocks for functions that might fail

## 2. Debugging Process

### Systematic Approach

- Start with isolated function testing before integration testing
- Use print statements or logging for complex debugging
- Test with minimal reproducible examples
- For R functions, ensure proper library dependencies are loaded

### Testing Data

- Create representative test data for each function
- Test edge cases (empty inputs, missing values, etc.)
- Document expected outputs for different inputs

## 3. Error Handling

- Implement informative error messages
- Use warning() for non-fatal issues
- Use stop() for critical failures
- Use tryCatch() for controlled error recovery

## 4. Documentation

- Document debugging steps and findings
- Maintain a record of common errors and their resolutions
- Include examples of valid inputs and expected outputs

## 5. Best Practices for R Function Debugging

1. **Function Definition Check**:
   - Ensure all functions have proper opening and closing curly braces
   - Check that function parameters are properly defined

2. **Input Validation**:
   - Add parameter type and value checking
   - Handle missing or NULL inputs gracefully

3. **Isolation Testing**:
   - Test functions in isolation using Rscript or in a fresh R session
   - Use minimal working examples

4. **Documentation**:
   - Use roxygen2-style documentation to clearly describe parameters and return values
   - Include examples of usage

Remember:
> "A function that cannot be run in isolation is not a reliable function."