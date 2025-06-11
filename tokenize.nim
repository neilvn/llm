# Simple tokenizer class

import std/algorithm
import std/re
import std/sets
import std/sequtils
import std/strutils

type InitType = enum
    filename = "filename"
    text = "text"

type Tokenizer = object
    filename: string = ""
    vocabulary: seq[(string, int)] = @[]
    text: string = ""


proc init(self: var Tokenizer, kind: InitType, data: string) =
    case kind
    of filename:
        self.filename = data
        self.text = readFile(self.filename)
    of text:
        self.text = data

    var tokenized = re.findAll(self.text, re"\w+|[,.]")
    var seen = toHashSet(tokenized)
    var unique_tokens = toSeq(seen)
    unique_tokens.sort()

    for i, token in unique_tokens:
        self.vocabulary.add((token, i))


proc encode(self: var Tokenizer, text: string): seq[int] =
    var preprocessed = re.findAll(text, re"\w+|[,.]")
    preprocessed = preprocessed.map(proc(word: string): string = strip(word))

    var ids: seq[int]
    for item in preprocessed:
        for vocab_item in self.vocabulary:
            if item == vocab_item[0]:
                ids.add(vocab_item[1]) 
                break
    return ids


proc decode(self: Tokenizer, ids: seq[int]): string =
    var text = ids
        .map(proc(id: int): string = self.vocabulary[id][0])
        .join(" ")

    # todo: remove whitespaces before punctuation
    return text


proc view(self: Tokenizer) = echo self.vocabulary


var tokenizer = Tokenizer()

tokenizer.init(filename, "example.txt")

let ids = tokenizer.encode(""""It's the last he painted, you know,"
Mrs. Gisburn said with pardonable pride.""")

let decoded = tokenizer.decode(ids)

echo decoded
