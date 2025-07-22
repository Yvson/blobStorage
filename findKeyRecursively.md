To search for the key `"values_from_list"` in a dictionary, including within nested dictionaries and arrays, you can use a **recursive function** in Python. This approach will traverse the dictionary and its nested structures (dictionaries, lists, or other iterables) to find all occurrences of the key `"values_from_list"`. Below is a solution that handles this task efficiently.

### Solution
Here's a Python function that recursively searches for the key `"values_from_list"` and returns a list of values associated with that key, no matter how deeply nested it is:

```python
def find_values_from_list(data, target_key="values_from_list", result=None):
    """
    Recursively search for a target key in a nested dictionary or list and collect its values.
    
    Args:
        data: The input dictionary, list, or other data structure to search.
        target_key: The key to search for (default: "values_from_list").
        result: List to store found values (default: None, initialized as empty list).
    
    Returns:
        A list of values associated with the target key.
    """
    if result is None:
        result = []
    
    if isinstance(data, dict):
        for key, value in data.items():
            if key == target_key:
                result.append(value)
            # Recursively search nested dictionaries or lists
            if isinstance(value, (dict, list)):
                find_values_from_list(value, target_key, result)
    
    elif isinstance(data, list):
        for item in data:
            # Recursively search each item in the list
            if isinstance(item, (dict, list)):
                find_values_from_list(item, target_key, result)
    
    return result

# Example usage
example_data = {
    "a": 1,
    "values_from_list": [1, 2, 3],
    "b": {
        "c": "test",
        "values_from_list": ["nested", "values"],
        "d": [
            {"values_from_list": [4, 5, 6]},
            {"e": "other", "values_from_list": [7, 8]}
        ]
    },
    "e": ["string", {"values_from_list": [9]}]
}

# Find all values associated with "values_from_list"
result = find_values_from_list(example_data)
print(result)
```

### How It Works
1. **Function Definition**:
   - The function `find_values_from_list` takes three parameters:
     - `data`: The input data structure (dictionary, list, or other).
     - `target_key`: The key to search for (defaults to `"values_from_list"`).
     - `result`: A list to store the values associated with the target key (initialized as an empty list if `None`).

2. **Base Case**:
   - If `result` is `None`, it initializes an empty list to store the results.

3. **Dictionary Handling**:
   - If the input `data` is a dictionary, the function iterates through its key-value pairs.
   - If the key matches `target_key`, the corresponding value is appended to the `result` list.
   - If the value is a dictionary or list, the function recursively calls itself on that value to search for nested occurrences of the key.

4. **List Handling**:
   - If the input `data` is a list, the function iterates through each item.
   - If an item is a dictionary or list, the function recursively calls itself on that item.

5. **Other Types**:
   - If the input is neither a dictionary nor a list (e.g., string, integer), the function does nothing and continues to the next item.

6. **Return**:
   - The function returns the `result` list containing all values associated with the `target_key`.

### Example Output
For the `example_data` dictionary above, the output would be:
```python
[[1, 2, 3], ['nested', 'values'], [4, 5, 6], [7, 8], [9]]
```

### Explanation of the Example
- The top-level `"values_from_list"` key has the value `[1, 2, 3]`.
- The nested dictionary under key `"b"` has a `"values_from_list"` key with value `["nested", "values"]`.
- The list under key `"d"` contains two dictionaries:
  - The first has a `"values_from_list"` key with value `[4, 5, 6]`.
  - The second has a `"values_from_list"` key with value `[7, 8]`.
- The list under key `"e"` contains a dictionary with a `"values_from_list"` key with value `[9]`.

### Additional Notes
- **Flexibility**: The function works for any nested structure, including dictionaries within lists within dictionaries, etc.
- **Performance**: The function is efficient for most practical cases, as it only traverses the data structure once.
- **Customization**: If you need the paths to the keys (e.g., `"b.d[0].values_from_list"`), you can modify the function to track the path during recursion. Here's an example of how to extend it:

```python
def find_values_from_list_with_path(data, target_key="values_from_list", result=None, path=None):
    """
    Recursively search for a target key and collect its values with their paths.
    
    Args:
        data: The input dictionary, list, or other data structure.
        target_key: The key to search for.
        result: List to store (path, value) tuples.
        path: Current path in the data structure.
    
    Returns:
        A list of (path, value) tuples.
    """
    if result is None:
        result = []
    if path is None:
        path = []
    
    if isinstance(data, dict):
        for key, value in data.items():
            current_path = path + [key]
            if key == target_key:
                result.append((".".join(str(p) for p in current_path), value))
            if isinstance(value, (dict, list)):
                find_values_from_list_with_path(value, target_key, result, current_path)
    
    elif isinstance(data, list):
        for i, item in enumerate(data):
            current_path = path + [f"[{i}]"]
            if isinstance(item, (dict, list)):
                find_values_from_list_with_path(item, target_key, result, current_path)
    
    return result

# Example usage with paths
result_with_path = find_values_from_list_with_path(example_data)
for path, value in result_with_path:
    print(f"Path: {path}, Value: {value}")
```

### Output with Paths
```python
Path: values_from_list, Value: [1, 2, 3]
Path: b.values_from_list, Value: ['nested', 'values']
Path: b.d[0].values_from_list, Value: [4, 5, 6]
Path: b.d[1].values_from_list, Value: [7, 8]
Path: e[1].values_from_list, Value: [9]
```

### When to Use
- Use the first function (`find_values_from_list`) if you only need the values.
- Use the second function (`find_values_from_list_with_path`) if you need to know where the keys are located in the structure.

If you have a specific dictionary structure or additional requirements (e.g., handling other iterable types, specific output format), let me know, and I can tailor the solution further!