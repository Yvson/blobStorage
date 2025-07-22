To access data in a Python dictionary using a path string like `"b.d[1].values_from_list"`, you need to parse the path and traverse the nested dictionary/list structure accordingly. The path string contains dot (`.`) notation for dictionary keys and bracket notation (`[n]`) for list indices. Below is a Python function that takes a dictionary and a path string, then returns the value at that path.

### Solution
Here’s a function that processes a path string and retrieves the corresponding value from a nested dictionary/list structure:

```python
def access_data_by_path(data, path):
    """
    Access a value in a nested dictionary/list using a path string.
    
    Args:
        data: The nested dictionary/list to traverse.
        path: A string representing the path (e.g., "b.d[1].values_from_list").
    
    Returns:
        The value at the specified path.
        
    Raises:
        KeyError: If a dictionary key is not found.
        IndexError: If a list index is out of range.
        ValueError: If the path is invalid or cannot be parsed.
    """
    # Split the path into components
    parts = path.replace("[", ".[").split(".")
    current = data
    
    for part in parts:
        if part.startswith("[") and part.endswith("]"):
            # Handle list index
            try:
                index = int(part[1:-1])  # Extract index from [n]
                if not isinstance(current, list):
                    raise ValueError(f"Expected a list at {part}, but got {type(current).__name__}")
                current = current[index]
            except ValueError as e:
                raise ValueError(f"Invalid index in path: {part}") from e
            except IndexError as e:
                raise IndexError(f"Index {part} out of range") from e
        else:
            # Handle dictionary key
            if not isinstance(current, dict):
                raise ValueError(f"Expected a dictionary at {part}, but got {type(current).__name__}")
            if part not in current:
                raise KeyError(f"Key {part} not found in dictionary")
            current = current[part]
    
    return current

# Example usage
if __name__ == "__main__":
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

    # Test accessing the value at "b.d[1].values_from_list"
    path = "b.d[1].values_from_list"
    try:
        value = access_data_by_path(example_data, path)
        print(f"Value at {path}: {value}")
    except (KeyError, IndexError, ValueError) as e:
        print(f"Error: {e}")
```

### How It Works
1. **Path Parsing**:
   - The path string (e.g., `"b.d[1].values_from_list"`) is split into components. To handle list indices correctly, `[n]` is treated as a single component by first replacing `[` with `.[` and then splitting on `.`.
   - This results in parts like `["b", "d", "[1]", "values_from_list"]`.

2. **Traversal**:
   - Start with the input dictionary (`data`) as the `current` object.
   - For each part in the path:
     - If the part is a dictionary key (e.g., `"b"`, `"d"`, `"values_from_list"`), access the dictionary using that key.
     - If the part is a list index (e.g., `"[1]"`), extract the index number, convert it to an integer, and access the list at that index.
   - Update `current` to the new value after each step.

3. **Error Handling**:
   - Raises `KeyError` if a dictionary key is not found.
   - Raises `IndexError` if a list index is out of range.
   - Raises `ValueError` if the path is invalid (e.g., trying to use a key on a list or an index on a dictionary).

4. **Return**:
   - Returns the value at the specified path.

### Example Output
For the given `example_data` and path `"b.d[1].values_from_list"`, the output is:
```
Value at b.d[1].values_from_list: [7, 8]
```

### Explanation
- Start at `example_data`.
- Access key `"b"`: `example_data["b"]` → `{"c": "test", "values_from_list": ["nested", "values"], "d": [...]}`.
- Access key `"d"`: `example_data["b"]["d"]` → `[{"values_from_list": [4, 5, 6]}, {"e": "other", "values_from_list": [7, 8]}]`.
- Access index `[1]`: `example_data["b"]["d"][1]` → `{"e": "other", "values_from_list": [7, 8]}`.
- Access key `"values_from_list"`: `example_data["b"]["d"][1]["values_from_list"]` → `[7, 8]`.

### Notes
- **Path Format**: The function assumes paths are in the format `key1.key2[index].key3`, where keys are separated by dots and list indices are in square brackets (e.g., `[n]`).
- **Error Handling**: The function provides clear error messages for invalid paths, missing keys, or out-of-range indices.
- **Flexibility**: Works for any nested combination of dictionaries and lists, as long as the path is valid.

If you need to handle additional cases (e.g., different path formats, or validating the path beforehand), let me know, and I can adjust the function!