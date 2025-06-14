import std/sequtils
    

proc find[T](items: seq[T], condition: proc(item: T): bool): int =
    for i, item in items:
        if condition(item):
           return i
    return -1
    
