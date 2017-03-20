# exadserver

xor
((inclusive == true and
      (storedValue == "all" or storedValue == value))
  or (inclusive == false and storedValue != value))
and not((inclusive == true and
      (storedValue == "all" or storedValue == value))
  and (inclusive == false and storedValue != value))
