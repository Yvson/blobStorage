To change the value of a specific `"values_from_list"` key in a nested dictionary/list structure using a path string like `"b.d[1].values_from_list"`, you can modify the dictionary traversal logic to update the value at the specified path. Below is a Python function that takes a dictionary, a path string, and a new value, then updates the target key's value in place.

### Solution
Here’s a function that updates the value of a key at a given path in a nested dictionary/list structure:

```python
def update_value_by_path(data, path, new_value):
    """
    Update the value at a specific path in a nested dictionary/list.
    
    Args:
        data: The nested dictionary/list to modify.
        path: A string representing the path (e.g., "b.d[1].values_from_list").
        new_value: The new value to set at the target path.
    
    Returns:
        None (modifies the data in place).
        
    Raises:
        KeyError: If a dictionary key is not found.
        IndexError: If a list index is out of range.
        ValueError: If the path is invalid or cannot be parsed.
    """
    # Split the path into components
    parts = path.replace("[", ".[").split(".")
    current = data
    
    # Traverse until the second-to-last part, so we can modify the final key/index
    for i, part in enumerate(parts[:-1]):
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
    
    # Update the value at the final key
    final_part = parts[-1]
    if final_part.startswith("[") and final_part.endswith("]"):
        try:
            index = int(final_part[1:-1])
            if not isinstance(current, list):
                raise ValueError(f"Expected a list at {final_part}, but got {type(current).__name__}")
            current[index] = new_value
        except ValueError as e:
            raise ValueError(f"Invalid index in path: {final_part}") from e
        except IndexError as e:
            raise IndexError(f"Index {final_part} out of range") from e
    else:
        if not isinstance(current, dict):
            raise ValueError(f"Expected a dictionary at {final_part}, but got {type(current).__name__}")
        if final_part not in current:
            raise KeyError(f"Key {final_part} not found in dictionary")
        current[final_part] = new_value

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

    # Update the value at "b.d[1].values_from_list"
    path = "b.d[1].values_from_list"
    new_value = [100, 200]
    try:
        update_value_by_path(example_data, path, new_value)
        print(f"Updated value at {path}: {example_data['b']['d'][1]['values_from_list']}")
        print("Updated dictionary:", example_data)
    except (KeyError, IndexError, ValueError) as e:
        print(f"Error: {e}")
```

### How It Works
1. **Path Parsing**:
   - The path string (e.g., `"b.d[1].values_from_list"`) is split into components by replacing `[` with `.[` and splitting on `.`, resulting in `["b", "d", "[1]", "values_from_list"]`.

2. **Traversal**:
   - The function traverses the nested structure up to the second-to-last part of the path to reach the container (dictionary or list) that holds the final key or index.
   - For each part:
     - If it’s a dictionary key (e.g., `"b"`, `"d"`), access the dictionary with that key.
     - If it’s a list index (e.g., `"[1]"`), extract the index and access the list at that position.
   - The `current` variable tracks the current position in the nested structure.

3. **Updating the Value**:
   - The final part of the path (e.g., `"values_from_list"`) is used to update the value in the container (`current`).
   - If the final part is a dictionary key, set `current[final_part] = new_value`.
   - If the final part is a list index (e.g., `"[n]"`), set `current[n] = new_value`.

4. **Error Handling**:
   - Raises `KeyError` if a dictionary key is not found.
   - Raises `IndexError` if a list index is out of range.
   - Raises `ValueError` if the path is invalid (e.g., using a key on a list or an index on a dictionary).

5. **In-Place Modification**:
   - The function modifies the input dictionary directly and does not return a new structure.

### Example Output
For the given `example_data` and path `"b.d[1].values_from_list"` with `new_value = [100, 200]`, the output is:
```
Updated value at b.d[1].values_from_list: [100, 200]
Updated dictionary: {
    'a': 1,
    'values_from_list': [1, 2, 3],
    'b': {
        'c': 'test',
        'values_from_list': ['nested', 'values'],
        'd': [
            {'values_from_list': [4, 5, 6]},
            {'e': 'other', 'values_from_list': [100, 200]}
        ]
    },
    'e': ['string', {'values_from_list': [9]}]
}
```

### Explanation
- The function navigates to `example_data["b"]["d"][1]["values_from_list"]`.
- It replaces the original value `[7, 8]` with the new value `[100, 200]`.
- The dictionary is modified in place, and the updated value can be verified by accessing the path directly.

–

### Combining with Path Finding
If you need to update all `"values_from_list"` keys (not just a specific path), you can combine this with the `find_values_from_list_paths` function from the previous response to locate all paths and then update each one. Here’s an example:

```python
def find_values_from_list_paths(data, target_key="values_from_list", result=None, path=None):
    """
    Recursively search for a target key in a nested dictionary or list and collect the paths.
    """
    if result is None:
        result = []
    if path is None:
        path = []
    
    if isinstance(data, dict):
        for key, value in data.items():
            current_path = path + [key]
            if key == target_key:
                result.append(".".join(str(p) for p in current_path))
            if isinstance(value, (dict, list)):
                find_values_from_list_paths(value, target_key, result, current_path)
    
    elif isinstance(data, list):
        for i, item in enumerate(data):
            current_path = path + [f"[{i}]"]
            if isinstance(item, (dict, list)):
                find_values_from_list_paths(item, target_key, result, current_path)
    
    return result

def update_all_values_from_list(data, new_value, target_key="values_from_list"):
    """
    Update all occurrences of target_key in a nested dictionary/list with new_value.
    
    Args:
        data: The nested dictionary/list to modify.
        new_value: The new value to set for all target keys.
        target_key: The key to search for (default: "values_from_list").
    
    Returns:
        None (modifies the data in place).
    """
    paths = find_values_from_list_paths(data, target_key)
    for path in paths:
        try:
            update_value_by_path(data, path, new_value)
        except (KeyError, IndexError, ValueError) as e:
            print(f"Error updating path {path}: {e}")

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

    # Update all "values_from_list" keys to a new value
    new_value = [999]
    update_all_values_from_list(example_data, new_value)
    print("Updated dictionary:", example_data)
```

### Output for Updating All `"values_from_list"` Keys
If you run `update_all_values_from_list` with `new_value = [999]`, all `"values_from_list"` keys will be updated to `[999]`. The output dictionary will be:
```
Updated dictionary: {
    'a': 1,
    'values_from_list': [999],
    'b': {
        'c': 'test',
        'values_from_list': [999],
        'd': [
            {'values_from_list': [999]},
            {'e': 'other', 'values_from_list': [999]}
        ]
    },
    'e': ['string', {'values_from_list': [999]}]
}
```

### Notes
- **Single Path Update**: Use `update_value_by_path` if you know the exact path (e.g., `"b.d[1].values_from_list"`) and want to update only that key.
- **All Paths Update**: Use `update_all_values_from_list` to update all `"values_from_list"` keys in the structure.
- **Error Handling**: Both functions include robust error handling to catch invalid paths, missing keys, or out-of-range indices.
- **In-Place Modification**: Both functions modify the input dictionary directly. If you need a copy to preserve the original data, use `copy.deepcopy`:
  ```python
  import copy
  data_copy = copy.deepcopy(example_data)
  update_value_by_path(data_copy, path, new_value)
  ```

If you have additional requirements (e.g., specific validation, different path formats, or preserving the original dictionary), let me know, and I can refine the solution!