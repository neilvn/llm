import std/tables
import std/sequtils
import std/strformat
import std/strutils
import std/algorithm

type
    BPE* = object
        vocab: Table[string, int]
        merges: seq[(string, string)]


proc newBPE*(): BPE =
    result.vocab = initTable[string, int]()
    result.merges = @[]


proc getWordFreqs(text: string): Table[string, int] =
    result = initTable[string, int]()
    let words = text.split()
    for word in words:
        let wordWithEnd = word & "</w>"
        if wordWithEnd in result:
            result[wordWithEnd] += 1
        else:
            result[wordWithEnd] = 1


proc getPairs(word: seq[string]): seq[(string, string)] =
    result = @[]
    for i in 0..<(word.len - 1):
        result.add((word[i], word[i + 1]))


proc getMostFrequentPair(wordFreqs: Table[string, int]): (string, string) =
    var pairCounts = initTable[(string, string), int]()

    for word, freq in wordFreqs:
        let chars = word.split(" ")
        let pairs = getPairs(chars)
        for pair in pairs:
            if pair in pairCounts:
                pairCounts[pair] += freq
            else:
                pairCounts[pair] = freq

    var maxCount = 0
    var bestPair = ("", "")
    for pair, count in pairCounts:
        if count > maxCount:
            maxCount = count
            bestPair = pair

    return bestPair


proc mergePair(wordFreqs: var Table[string, int], pair: (string, string)): Table[string, int] =
    result = initTable[string, int]()
    let (first, second) = pair
    let target = first & second
    let pattern = first & " " & second

    for word, freq in wordFreqs:
        let newWord = word.replace(pattern, target)
        result[newWord] = freq


proc train*(bpe: var BPE, text: string, numMerges: int) =
    var wordFreqs = getWordFreqs(text)

    for word in wordFreqs.keys:
        for ch in word:
            let char = $ch
            if char notin bpe.vocab:
                bpe.vocab[char] = bpe.vocab.len

    if " " notin bpe.vocab:
        bpe.vocab[" "] = bpe.vocab.len

    var spacedWordFreqs = initTable[string, int]()
    for word, freq in wordFreqs:
        let base = word[0..^5]  # Remove </w>
        var tokens = base.toSeq().mapIt($it)
        tokens.add("</w>")
        let spacedWord = tokens.join(" ")
        spacedWordFreqs[spacedWord] = freq

    for i in 0..<numMerges:
        let mostFreqPair = getMostFrequentPair(spacedWordFreqs)
        if mostFreqPair == ("", ""):
            break

        bpe.merges.add(mostFreqPair)

        let mergedToken = mostFreqPair[0] & mostFreqPair[1]
        if mergedToken notin bpe.vocab:
            bpe.vocab[mergedToken] = bpe.vocab.len

        spacedWordFreqs = mergePair(spacedWordFreqs, mostFreqPair)


proc encode*(bpe: BPE, text: string): seq[string] =
    result = @[]
    let words = text.split()

    for word in words:
        var wordTokens = word.toSeq().mapIt($it)
        wordTokens.add("</w>")

        for (first, second) in bpe.merges:
            var i = 0
            while i < wordTokens.len - 1:
                if wordTokens[i] == first and wordTokens[i + 1] == second:
                    wordTokens[i] = first & second
                    wordTokens.delete(i + 1)
                    i = max(0, i - 1)
                else:
                    i += 1

        result.add(wordTokens)


proc decode*(bpe: BPE, tokens: seq[string]): string =
    result = tokens.join("").replace("</w>", " ").strip()


# Example usage
when isMainModule:
    var bpe = newBPE()
    let text = "low lower newest widest"

    bpe.train(text, 10)

    echo "\nEncoding examples:"
    let testWords = ["low", "higher", "newest", "widest"]
    for word in testWords:
        let encoded = bpe.encode(word)
        let decoded = bpe.decode(encoded)
        echo fmt"  '{word}' -> {encoded} -> '{decoded}'"
