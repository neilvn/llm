# Simple tokenizer class

import std/algorithm
import std/re
import std/sets
import std/sequtils
import std/strformat
import std/strutils
import std/sugar


const
    END_OF_TEXT = "endoftext"
    END_OF_TEXT_TK = fmt"<|{END_OF_TEXT}|>"
    UNKNOWN_TK = "<|unk|>"


type InitType = enum
    filename
    text


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

    var tokenized = re.findAll(self.text, re"""\w+|[,."'"]""")
    var seen = toHashSet(tokenized)
    var unique_tokens = toSeq(seen)
    unique_tokens.sort()

    unique_tokens.add(END_OF_TEXT_TK)
    unique_tokens.add(UNKNOWN_TK)

    for i, token in unique_tokens:
        self.vocabulary.add((token, i))


proc get_token_id(self: Tokenizer, word: string): int =
    if word == END_OF_TEXT:
        return -2

    for i, token in self.vocabulary:
        if token[0] == word:
            return i
    return -1


proc encode(self: var Tokenizer, text: string): seq[int] =
    let unk_id = self.get_token_id(UNKNOWN_TK)
    let endoftext_id = self.get_token_id(END_OF_TEXT_TK)
    var preprocessed = re.findAll(text, re"""\w+|[,."'"]""")
    preprocessed = preprocessed.map((word: string) => strip(word))

    var ids: seq[int]
    for item in preprocessed:
        let id = self.get_token_id(item)
        if id == -1:
            ids.add(unk_id)
        elif id == -2:
            ids.add(endoftext_id)
        else:
            ids.add(id) 
            
    return ids


proc decode(self: Tokenizer, ids: seq[int]): string =
    var text = ids.map((id: int) => self.vocabulary[id][0]).join(" ")

    # todo: remove whitespaces before punctuation
    return text


proc test() =
    var tokenizer = Tokenizer()

    tokenizer.init(filename, "example.txt")

    let text1 = "Hello, do you like tea?"
    let text2 = "In the sunlit terraces of the palace."
    let text = @[text1, text2].join(fmt" {END_OF_TEXT_TK} ")

    let ids = tokenizer.encode(text)

    let decoded = tokenizer.decode(ids)

    echo decoded


test()
