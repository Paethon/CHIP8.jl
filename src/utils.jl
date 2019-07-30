"""
Returns true if there was a collision between original and sprite
"""
collision(original, sprite) = (original & sprite) != 0

"""
Return the single bits of line as an iterator
"""
decode(line::Integer) = Iterators.reverse(digits(line, base = 2, pad = sizeof(line)*8))
