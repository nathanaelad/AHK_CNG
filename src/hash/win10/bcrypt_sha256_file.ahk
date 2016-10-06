﻿MsgBox % bcrypt_sha256_file("C:\Windows\notepad.exe")
; ==> da0acee8f60a460cfb5249e262d3d53211ebc4c777579e99c8202b761541110a



bcrypt_sha256_file(filename)
{
    static BCRYPT_SHA256_ALGORITHM := "SHA256"
    static BCRYPT_OBJECT_LENGTH    := "ObjectLength"
    static BCRYPT_HASH_LENGTH      := "HashDigestLength"

    if !(hBCRYPT := DllCall("LoadLibrary", "str", "bcrypt.dll", "ptr"))
        throw Exception("Failed to load bcrypt.dll", -1)

    if (NT_STATUS := DllCall("bcrypt\BCryptOpenAlgorithmProvider", "ptr*", hAlgo, "ptr", &BCRYPT_SHA256_ALGORITHM, "ptr", 0, "uint", 0) != 0)
        throw Exception("BCryptOpenAlgorithmProvider: " NT_STATUS, -1)

    if (NT_STATUS := DllCall("bcrypt\BCryptGetProperty", "ptr", hAlgo, "ptr", &BCRYPT_HASH_LENGTH, "uint*", cbHash, "uint", 4, "uint*", cbResult, "uint", 0) != 0)
        throw Exception("BCryptGetProperty: " NT_STATUS, -1)

    VarSetCapacity(pbHash, cbHash, 0)
    if !(f := FileOpen(filename, "r", "UTF-8"))
        throw Exception("Failed to open file: " filename, -1)
    while !(f.AtEOF) && (dataread := f.RawRead(data, 262144))
        if (NT_STATUS := DllCall("bcrypt\BCryptHash", "ptr", hAlgo, "ptr", 0, "uint", 0, "ptr", &data, "uint", dataread, "ptr", &pbHash, "uint", cbHash) != 0)
            throw Exception("BCryptHash: " NT_STATUS, -1)
    f.Close()

    loop % cbHash
        hash .= Format("{:02x}", NumGet(pbHash, A_Index - 1, "UChar"))

    DllCall("bcrypt\BCryptCloseAlgorithmProvider", "ptr", hAlgo, "uint", 0)
    DllCall("FreeLibrary", "ptr", hBCRYPT)

    return hash
}