"""Unicode character class tables for the pre-tokenizer.

Generated from Unicode Character Database (Unicode 15.1).

Provides two predicates:
  is_letter(cp)  -- true for General_Category = L* (Lu Ll Lt Lm Lo)
  is_number(cp)  -- true for General_Category = N* (Nd Nl No)

Range tables are inlined as if-chains (global variables not supported in Mojo).
"""


def is_letter(cp: Int) -> Bool:
    """True if Unicode code point cp is in General_Category L* (letter)."""
    if cp < 0x0041:
        return False
    if cp <= 0x005A:
        return True
    if cp < 0x0061:
        return False
    if cp <= 0x007A:
        return True
    if cp < 0x00AA:
        return False
    if cp <= 0x00AA:
        return True
    if cp < 0x00B5:
        return False
    if cp <= 0x00B5:
        return True
    if cp < 0x00BA:
        return False
    if cp <= 0x00BA:
        return True
    if cp < 0x00C0:
        return False
    if cp <= 0x00D6:
        return True
    if cp < 0x00D8:
        return False
    if cp <= 0x00F6:
        return True
    if cp < 0x00F8:
        return False
    if cp <= 0x02C1:
        return True
    if cp < 0x0100:
        return False
    if cp <= 0x02C1:
        return True
    if cp < 0x0250:
        return False
    if cp <= 0x02AF:
        return True
    if cp < 0x02B0:
        return False
    if cp <= 0x02B8:
        return True
    if cp < 0x02C6:
        return False
    if cp <= 0x02D1:
        return True
    if cp < 0x02E0:
        return False
    if cp <= 0x02E4:
        return True
    if cp < 0x0370:
        return False
    if cp <= 0x0374:
        return True
    if cp < 0x0374:
        return False
    if cp <= 0x0375:
        return True
    if cp < 0x0376:
        return False
    if cp <= 0x0377:
        return True
    if cp < 0x037B:
        return False
    if cp <= 0x037D:
        return True
    if cp < 0x037F:
        return False
    if cp <= 0x037F:
        return True
    if cp < 0x0386:
        return False
    if cp <= 0x0386:
        return True
    if cp < 0x0388:
        return False
    if cp <= 0x038A:
        return True
    if cp < 0x038C:
        return False
    if cp <= 0x038C:
        return True
    if cp < 0x038E:
        return False
    if cp <= 0x03A1:
        return True
    if cp < 0x03A3:
        return False
    if cp <= 0x03CE:
        return True
    if cp < 0x03F0:
        return False
    if cp <= 0x0481:
        return True
    if cp < 0x0400:
        return False
    if cp <= 0x052F:
        return True
    if cp < 0x048A:
        return False
    if cp <= 0x04C0:
        return True
    if cp < 0x04C0:
        return False
    if cp <= 0x04CD:
        return True
    if cp < 0x04D0:
        return False
    if cp <= 0x04FF:
        return True
    if cp < 0x0500:
        return False
    if cp <= 0x052F:
        return True
    if cp < 0x0531:
        return False
    if cp <= 0x0556:
        return True
    if cp < 0x0559:
        return False
    if cp <= 0x0559:
        return True
    if cp < 0x0561:
        return False
    if cp <= 0x0587:
        return True
    if cp < 0x05D0:
        return False
    if cp <= 0x05EA:
        return True
    if cp < 0x05EF:
        return False
    if cp <= 0x05F2:
        return True
    if cp < 0x0620:
        return False
    if cp <= 0x063F:
        return True
    if cp < 0x0640:
        return False
    if cp <= 0x0640:
        return True
    if cp < 0x0641:
        return False
    if cp <= 0x064A:
        return True
    if cp < 0x066E:
        return False
    if cp <= 0x066F:
        return True
    if cp < 0x0671:
        return False
    if cp <= 0x06D3:
        return True
    if cp < 0x06D5:
        return False
    if cp <= 0x06D5:
        return True
    if cp < 0x06E5:
        return False
    if cp <= 0x06E6:
        return True
    if cp < 0x06EE:
        return False
    if cp <= 0x06EF:
        return True
    if cp < 0x06FA:
        return False
    if cp <= 0x06FC:
        return True
    if cp < 0x06FF:
        return False
    if cp <= 0x06FF:
        return True
    if cp < 0x0710:
        return False
    if cp <= 0x0710:
        return True
    if cp < 0x0712:
        return False
    if cp <= 0x072F:
        return True
    if cp < 0x074D:
        return False
    if cp <= 0x07A5:
        return True
    if cp < 0x07CA:
        return False
    if cp <= 0x07EA:
        return True
    if cp < 0x07F4:
        return False
    if cp <= 0x07F5:
        return True
    if cp < 0x07FA:
        return False
    if cp <= 0x07FA:
        return True
    if cp < 0x0800:
        return False
    if cp <= 0x0815:
        return True
    if cp < 0x081A:
        return False
    if cp <= 0x081A:
        return True
    if cp < 0x0824:
        return False
    if cp <= 0x0824:
        return True
    if cp < 0x0828:
        return False
    if cp <= 0x0828:
        return True
    if cp < 0x0840:
        return False
    if cp <= 0x0858:
        return True
    if cp < 0x0860:
        return False
    if cp <= 0x086A:
        return True
    if cp < 0x08A0:
        return False
    if cp <= 0x08B4:
        return True
    if cp < 0x08B6:
        return False
    if cp <= 0x08C7:
        return True
    if cp < 0x08D4:
        return False
    if cp <= 0x08E0:
        return True
    if cp < 0x0900:
        return False
    if cp <= 0x093F:
        return True
    if cp < 0x0950:
        return False
    if cp <= 0x0950:
        return True
    if cp < 0x0958:
        return False
    if cp <= 0x0963:
        return True
    if cp < 0x0966:
        return False
    if cp <= 0x096F:
        return True
    if cp < 0x0971:
        return False
    if cp <= 0x097F:
        return True
    if cp < 0x0985:
        return False
    if cp <= 0x098C:
        return True
    if cp < 0x098F:
        return False
    if cp <= 0x0990:
        return True
    if cp < 0x0993:
        return False
    if cp <= 0x09A8:
        return True
    if cp < 0x09AA:
        return False
    if cp <= 0x09B0:
        return True
    if cp < 0x09B2:
        return False
    if cp <= 0x09B2:
        return True
    if cp < 0x09B6:
        return False
    if cp <= 0x09B9:
        return True
    if cp < 0x09BD:
        return False
    if cp <= 0x09BD:
        return True
    if cp < 0x09CE:
        return False
    if cp <= 0x09CE:
        return True
    if cp < 0x09DC:
        return False
    if cp <= 0x09DD:
        return True
    if cp < 0x09DF:
        return False
    if cp <= 0x09E3:
        return True
    if cp < 0x09F0:
        return False
    if cp <= 0x09F1:
        return True
    if cp < 0x09FC:
        return False
    if cp <= 0x09FC:
        return True
    if cp < 0x0A05:
        return False
    if cp <= 0x0A0A:
        return True
    if cp < 0x0A0F:
        return False
    if cp <= 0x0A10:
        return True
    if cp < 0x0A13:
        return False
    if cp <= 0x0A28:
        return True
    if cp < 0x0A2A:
        return False
    if cp <= 0x0A30:
        return True
    if cp < 0x0A32:
        return False
    if cp <= 0x0A33:
        return True
    if cp < 0x0A35:
        return False
    if cp <= 0x0A36:
        return True
    if cp < 0x0A38:
        return False
    if cp <= 0x0A39:
        return True
    if cp < 0x0A3E:
        return False
    if cp <= 0x0A42:
        return True
    if cp < 0x0A59:
        return False
    if cp <= 0x0A5C:
        return True
    if cp < 0x0A5C:
        return False
    if cp <= 0x0A5C:
        return True
    if cp < 0x0A5E:
        return False
    if cp <= 0x0A5E:
        return True
    if cp < 0x0A72:
        return False
    if cp <= 0x0A74:
        return True
    if cp < 0x0A85:
        return False
    if cp <= 0x0A8D:
        return True
    if cp < 0x0A8F:
        return False
    if cp <= 0x0A91:
        return True
    if cp < 0x0A93:
        return False
    if cp <= 0x0AA8:
        return True
    if cp < 0x0AAA:
        return False
    if cp <= 0x0AB0:
        return True
    if cp < 0x0AB2:
        return False
    if cp <= 0x0AB3:
        return True
    if cp < 0x0AB5:
        return False
    if cp <= 0x0AB9:
        return True
    if cp < 0x0ABD:
        return False
    if cp <= 0x0ABD:
        return True
    if cp < 0x0AD0:
        return False
    if cp <= 0x0AD0:
        return True
    if cp < 0x0AE0:
        return False
    if cp <= 0x0AE3:
        return True
    if cp < 0x0AF9:
        return False
    if cp <= 0x0AF9:
        return True
    if cp < 0x0B05:
        return False
    if cp <= 0x0B0C:
        return True
    if cp < 0x0B0F:
        return False
    if cp <= 0x0B10:
        return True
    if cp < 0x0B13:
        return False
    if cp <= 0x0B28:
        return True
    if cp < 0x0B2A:
        return False
    if cp <= 0x0B30:
        return True
    if cp < 0x0B32:
        return False
    if cp <= 0x0B33:
        return True
    if cp < 0x0B35:
        return False
    if cp <= 0x0B39:
        return True
    if cp < 0x0B3D:
        return False
    if cp <= 0x0B3D:
        return True
    if cp < 0x0B5C:
        return False
    if cp <= 0x0B5D:
        return True
    if cp < 0x0B5F:
        return False
    if cp <= 0x0B61:
        return True
    if cp < 0x0B83:
        return False
    if cp <= 0x0B83:
        return True
    if cp < 0x0B85:
        return False
    if cp <= 0x0B8A:
        return True
    if cp < 0x0B8E:
        return False
    if cp <= 0x0B90:
        return True
    if cp < 0x0B92:
        return False
    if cp <= 0x0B95:
        return True
    if cp < 0x0B99:
        return False
    if cp <= 0x0B9A:
        return True
    if cp < 0x0B9C:
        return False
    if cp <= 0x0B9C:
        return True
    if cp < 0x0B9E:
        return False
    if cp <= 0x0B9F:
        return True
    if cp < 0x0BA3:
        return False
    if cp <= 0x0BA4:
        return True
    if cp < 0x0BA8:
        return False
    if cp <= 0x0BAA:
        return True
    if cp < 0x0BAE:
        return False
    if cp <= 0x0BB9:
        return True
    if cp < 0x0BD0:
        return False
    if cp <= 0x0BD0:
        return True
    if cp < 0x0C05:
        return False
    if cp <= 0x0C0C:
        return True
    if cp < 0x0C0E:
        return False
    if cp <= 0x0C10:
        return True
    if cp < 0x0C12:
        return False
    if cp <= 0x0C28:
        return True
    if cp < 0x0C2A:
        return False
    if cp <= 0x0C39:
        return True
    if cp < 0x0C3D:
        return False
    if cp <= 0x0C3D:
        return True
    if cp < 0x0C58:
        return False
    if cp <= 0x0C5A:
        return True
    if cp < 0x0C60:
        return False
    if cp <= 0x0C61:
        return True
    if cp < 0x0C80:
        return False
    if cp <= 0x0C80:
        return True
    if cp < 0x0C85:
        return False
    if cp <= 0x0C8C:
        return True
    if cp < 0x0C8E:
        return False
    if cp <= 0x0C90:
        return True
    if cp < 0x0C92:
        return False
    if cp <= 0x0CA8:
        return True
    if cp < 0x0CAA:
        return False
    if cp <= 0x0CB3:
        return True
    if cp < 0x0CB5:
        return False
    if cp <= 0x0CB9:
        return True
    if cp < 0x0CBD:
        return False
    if cp <= 0x0CBD:
        return True
    if cp < 0x0CDE:
        return False
    if cp <= 0x0CDE:
        return True
    if cp < 0x0CE0:
        return False
    if cp <= 0x0CE1:
        return True
    if cp < 0x0CF1:
        return False
    if cp <= 0x0CF2:
        return True
    if cp < 0x0D04:
        return False
    if cp <= 0x0D0C:
        return True
    if cp < 0x0D0E:
        return False
    if cp <= 0x0D10:
        return True
    if cp < 0x0D12:
        return False
    if cp <= 0x0D3A:
        return True
    if cp < 0x0D3D:
        return False
    if cp <= 0x0D3D:
        return True
    if cp < 0x0D4E:
        return False
    if cp <= 0x0D4E:
        return True
    if cp < 0x0D54:
        return False
    if cp <= 0x0D56:
        return True
    if cp < 0x0D5F:
        return False
    if cp <= 0x0D61:
        return True
    if cp < 0x0D7A:
        return False
    if cp <= 0x0D7F:
        return True
    if cp < 0x0D85:
        return False
    if cp <= 0x0D96:
        return True
    if cp < 0x0D9A:
        return False
    if cp <= 0x0DB1:
        return True
    if cp < 0x0DB3:
        return False
    if cp <= 0x0DBB:
        return True
    if cp < 0x0DBD:
        return False
    if cp <= 0x0DBD:
        return True
    if cp < 0x0DC0:
        return False
    if cp <= 0x0DC6:
        return True
    if cp < 0x0E01:
        return False
    if cp <= 0x0E30:
        return True
    if cp < 0x0E40:
        return False
    if cp <= 0x0E45:
        return True
    if cp < 0x0E81:
        return False
    if cp <= 0x0E82:
        return True
    if cp < 0x0E84:
        return False
    if cp <= 0x0E84:
        return True
    if cp < 0x0E86:
        return False
    if cp <= 0x0E8A:
        return True
    if cp < 0x0E8C:
        return False
    if cp <= 0x0EA3:
        return True
    if cp < 0x0EA5:
        return False
    if cp <= 0x0EA5:
        return True
    if cp < 0x0EA7:
        return False
    if cp <= 0x0EB0:
        return True
    if cp < 0x0EBD:
        return False
    if cp <= 0x0EBD:
        return True
    if cp < 0x0EC0:
        return False
    if cp <= 0x0EC4:
        return True
    if cp < 0x0EDC:
        return False
    if cp <= 0x0EDD:
        return True
    if cp < 0x0F00:
        return False
    if cp <= 0x0F00:
        return True
    if cp < 0x1000:
        return False
    if cp <= 0x102A:
        return True
    if cp < 0x103F:
        return False
    if cp <= 0x1049:
        return True
    if cp < 0x1050:
        return False
    if cp <= 0x1055:
        return True
    if cp < 0x105A:
        return False
    if cp <= 0x105D:
        return True
    if cp < 0x1065:
        return False
    if cp <= 0x1066:
        return True
    if cp < 0x106E:
        return False
    if cp <= 0x1070:
        return True
    if cp < 0x1075:
        return False
    if cp <= 0x107F:
        return True
    if cp < 0x108E:
        return False
    if cp <= 0x108E:
        return True
    if cp < 0x10A0:
        return False
    if cp <= 0x10C5:
        return True
    if cp < 0x10C7:
        return False
    if cp <= 0x10C7:
        return True
    if cp < 0x10CD:
        return False
    if cp <= 0x10CD:
        return True
    if cp < 0x10D0:
        return False
    if cp <= 0x10FA:
        return True
    if cp < 0x10FC:
        return False
    if cp <= 0x10FF:
        return True
    if cp < 0x1100:
        return False
    if cp <= 0x1248:
        return True
    if cp < 0x1200:
        return False
    if cp <= 0x1246:
        return True
    if cp < 0x1248:
        return False
    if cp <= 0x1248:
        return True
    if cp < 0x124A:
        return False
    if cp <= 0x124D:
        return True
    if cp < 0x1250:
        return False
    if cp <= 0x1256:
        return True
    if cp < 0x1257:
        return False
    if cp <= 0x1257:
        return True
    if cp < 0x1259:
        return False
    if cp <= 0x1259:
        return True
    if cp < 0x125B:
        return False
    if cp <= 0x125D:
        return True
    if cp < 0x1260:
        return False
    if cp <= 0x1286:
        return True
    if cp < 0x1288:
        return False
    if cp <= 0x1288:
        return True
    if cp < 0x128A:
        return False
    if cp <= 0x128D:
        return True
    if cp < 0x128E:
        return False
    if cp <= 0x128E:
        return True
    if cp < 0x1290:
        return False
    if cp <= 0x12B0:
        return True
    if cp < 0x12B2:
        return False
    if cp <= 0x12B5:
        return True
    if cp < 0x12B6:
        return False
    if cp <= 0x12BE:
        return True
    if cp < 0x12BE:
        return False
    if cp <= 0x12C0:
        return True
    if cp < 0x12C0:
        return False
    if cp <= 0x12C5:
        return True
    if cp < 0x12C2:
        return False
    if cp <= 0x12D6:
        return True
    if cp < 0x12C6:
        return False
    if cp <= 0x1310:
        return True
    if cp < 0x12D0:
        return False
    if cp <= 0x1315:
        return True
    if cp < 0x12D8:
        return False
    if cp <= 0x135A:
        return True
    if cp < 0x1310:
        return False
    if cp <= 0x138F:
        return True
    if cp < 0x1312:
        return False
    if cp <= 0x13F5:
        return True
    if cp < 0x1316:
        return False
    if cp <= 0x13FD:
        return True
    if cp < 0x1320:
        return False
    if cp <= 0x166C:
        return True
    if cp < 0x1380:
        return False
    if cp <= 0x1677:
        return True
    if cp < 0x13A0:
        return False
    if cp <= 0x16BA:
        return True
    if cp < 0x13F8:
        return False
    if cp <= 0x16F8:
        return True
    if cp < 0x1401:
        return False
    if cp <= 0x169A:
        return True
    if cp < 0x166F:
        return False
    if cp <= 0x16EA:
        return True
    if cp < 0x1681:
        return False
    if cp <= 0x1711:
        return True
    if cp < 0x16A0:
        return False
    if cp <= 0x1731:
        return True
    if cp < 0x16EE:
        return False
    if cp <= 0x1751:
        return True
    if cp < 0x16F1:
        return False
    if cp <= 0x1770:
        return True
    if cp < 0x1700:
        return False
    if cp <= 0x176C:
        return True
    if cp < 0x1720:
        return False
    if cp <= 0x17B3:
        return True
    if cp < 0x1740:
        return False
    if cp <= 0x17D7:
        return True
    if cp < 0x1760:
        return False
    if cp <= 0x17DC:
        return True
    if cp < 0x176E:
        return False
    if cp <= 0x18A8:
        return True
    if cp < 0x1780:
        return False
    if cp <= 0x18F5:
        return True
    if cp < 0x17D7:
        return False
    if cp <= 0x1C7D:
        return True
    if cp < 0x17DC:
        return False
    if cp <= 0x1C8A:
        return True
    if cp < 0x1820:
        return False
    if cp <= 0x1CBC:
        return True
    if cp < 0x1880:
        return False
    if cp <= 0x1CBF:
        return True
    if cp < 0x1C80:
        return False
    if cp <= 0x1CEB:
        return True
    if cp < 0x1C90:
        return False
    if cp <= 0x1CEC:
        return True
    if cp < 0x1CBB:
        return False
    if cp <= 0x1CF3:
        return True
    if cp < 0x1CBD:
        return False
    if cp <= 0x1CF6:
        return True
    if cp < 0x1CE9:
        return False
    if cp <= 0x1CFA:
        return True
    if cp < 0x1CEB:
        return False
    if cp <= 0x1DBF:
        return True
    if cp < 0x1CEE:
        return False
    if cp <= 0x1FFF:
        return True
    if cp < 0x1CF5:
        return False
    if cp <= 0x1FFF:
        return True
    if cp < 0x1CFA:
        return False
    if cp <= 0x2071:
        return True
    if cp < 0x1D00:
        return False
    if cp <= 0x207F:
        return True
    if cp < 0x1E00:
        return False
    if cp <= 0x209C:
        return True
    if cp < 0x1F00:
        return False
    if cp <= 0x2102:
        return True
    if cp < 0x2071:
        return False
    if cp <= 0x2107:
        return True
    if cp < 0x207F:
        return False
    if cp <= 0x2113:
        return True
    if cp < 0x2090:
        return False
    if cp <= 0x2115:
        return True
    if cp < 0x2102:
        return False
    if cp <= 0x211D:
        return True
    if cp < 0x2107:
        return False
    if cp <= 0x211D:
        return True
    if cp < 0x210A:
        return False
    if cp <= 0x2124:
        return True
    if cp < 0x2115:
        return False
    if cp <= 0x2126:
        return True
    if cp < 0x2119:
        return False
    if cp <= 0x2128:
        return True
    if cp < 0x211D:
        return False
    if cp <= 0x2138:
        return True
    if cp < 0x2124:
        return False
    if cp <= 0x213D:
        return True
    if cp < 0x2126:
        return False
    if cp <= 0x214E:
        return True
    if cp < 0x2128:
        return False
    if cp <= 0x2182:
        return True
    if cp < 0x212A:
        return False
    if cp <= 0x2184:
        return True
    if cp < 0x2139:
        return False
    if cp <= 0x218B:
        return True
    if cp < 0x213C:
        return False
    if cp <= 0x2CEE:
        return True
    if cp < 0x2145:
        return False
    if cp <= 0x2C6C:
        return True
    if cp < 0x214E:
        return False
    if cp <= 0x2C7F:
        return True
    if cp < 0x2160:
        return False
    if cp <= 0x2C6F:
        return True
    if cp < 0x2183:
        return False
    if cp <= 0x2C72:
        return True
    if cp < 0x2185:
        return False
    if cp <= 0x2C74:
        return True
    if cp < 0x2C00:
        return False
    if cp <= 0x2C76:
        return True
    if cp < 0x2C30:
        return False
    if cp <= 0x2C7E:
        return True
    if cp < 0x2C60:
        return False
    if cp <= 0x2CE4:
        return True
    if cp < 0x2C67:
        return False
    if cp <= 0x2CEB:
        return True
    if cp < 0x2C71:
        return False
    if cp <= 0x2CEE:
        return True
    if cp < 0x2C73:
        return False
    if cp <= 0x2CF2:
        return True
    if cp < 0x2C76:
        return False
    if cp <= 0x2D27:
        return True
    if cp < 0x2C7C:
        return False
    if cp <= 0x2D2D:
        return True
    if cp < 0x2C80:
        return False
    if cp <= 0x2D65:
        return True
    if cp < 0x2CE0:
        return False
    if cp <= 0x2D6F:
        return True
    if cp < 0x2CEB:
        return False
    if cp <= 0x2D96:
        return True
    if cp < 0x2CFF:
        return False
    if cp <= 0x2DA6:
        return True
    if cp < 0x2D27:
        return False
    if cp <= 0x2DAE:
        return True
    if cp < 0x2D2D:
        return False
    if cp <= 0x2DB6:
        return True
    if cp < 0x2D30:
        return False
    if cp <= 0x2DBE:
        return True
    if cp < 0x2D6F:
        return False
    if cp <= 0x2DC6:
        return True
    if cp < 0x2D80:
        return False
    if cp <= 0x2DCE:
        return True
    if cp < 0x2DA0:
        return False
    if cp <= 0x2DD6:
        return True
    if cp < 0x2DA8:
        return False
    if cp <= 0x2DDE:
        return True
    if cp < 0x2DB0:
        return False
    if cp <= 0x2E2F:
        return True
    if cp < 0x2DB8:
        return False
    if cp <= 0x3007:
        return True
    if cp < 0x2DC0:
        return False
    if cp <= 0x3029:
        return True
    if cp < 0x2DC8:
        return False
    if cp <= 0x303A:
        return True
    if cp < 0x2DD0:
        return False
    if cp <= 0x3097:
        return True
    if cp < 0x2DD8:
        return False
    if cp <= 0x3037:
        return True
    if cp < 0x2E2F:
        return False
    if cp <= 0x303B:
        return True
    if cp < 0x3005:
        return False
    if cp <= 0x303F:
        return True
    if cp < 0x3007:
        return False
    if cp <= 0x3096:
        return True
    if cp < 0x3021:
        return False
    if cp <= 0x309E:
        return True
    if cp < 0x302A:
        return False
    if cp <= 0x30A0:
        return True
    if cp < 0x3031:
        return False
    if cp <= 0x30FA:
        return True
    if cp < 0x3038:
        return False
    if cp <= 0x30FF:
        return True
    if cp < 0x303C:
        return False
    if cp <= 0x312F:
        return True
    if cp < 0x3041:
        return False
    if cp <= 0x318E:
        return True
    if cp < 0x3099:
        return False
    if cp <= 0x31BA:
        return True
    if cp < 0x309F:
        return False
    if cp <= 0x31FF:
        return True
    if cp < 0x30A1:
        return False
    if cp <= 0x9FEF:
        return True
    if cp < 0x30FF:
        return False
    if cp <= 0xA48C:
        return True
    if cp < 0x3105:
        return False
    if cp <= 0xA014:
        return True
    if cp < 0x3131:
        return False
    if cp <= 0xA015:
        return True
    if cp < 0x3190:
        return False
    if cp <= 0xA0C3:
        return True
    if cp < 0x31A0:
        return False
    if cp <= 0xA0C5:
        return True
    if cp < 0x31F0:
        return False
    if cp <= 0xA0C6:
        return True
    if cp < 0x3400:
        return False
    if cp <= 0xA60C:
        return True
    if cp < 0x4E00:
        return False
    if cp <= 0xA610:
        return True
    if cp < 0xA000:
        return False
    if cp <= 0xA61F:
        return True
    if cp < 0xA014:
        return False
    if cp <= 0xA62B:
        return True
    if cp < 0xA016:
        return False
    if cp <= 0xA6E5:
        return True
    if cp < 0xA090:
        return False
    if cp <= 0xA6EF:
        return True
    if cp < 0xA0C4:
        return False
    if cp <= 0xA6EF:
        return True
    if cp < 0xA0C7:
        return False
    if cp <= 0xA71F:
        return True
    if cp < 0xA500:
        return False
    if cp <= 0xA71F:
        return True
    if cp < 0xA60C:
        return False
    if cp <= 0xA788:
        return True
    if cp < 0xA610:
        return False
    if cp <= 0xA78A:
        return True
    if cp < 0xA62A:
        return False
    if cp <= 0xA7CA:
        return True
    if cp < 0xA640:
        return False
    if cp <= 0xA7FF:
        return True
    if cp < 0xA6A0:
        return False
    if cp <= 0xA801:
        return True
    if cp < 0xA6E6:
        return False
    if cp <= 0xA805:
        return True
    if cp < 0xA717:
        return False
    if cp <= 0xA80A:
        return True
    if cp < 0xA71F:
        return False
    if cp <= 0xA822:
        return True
    if cp < 0xA722:
        return False
    if cp <= 0xA873:
        return True
    if cp < 0xA788:
        return False
    if cp <= 0xA881:
        return True
    if cp < 0xA78B:
        return False
    if cp <= 0xA8B3:
        return True
    if cp < 0xA7C2:
        return False
    if cp <= 0xA8F7:
        return True
    if cp < 0xA7F7:
        return False
    if cp <= 0xA8FB:
        return True
    if cp < 0xA7FB:
        return False
    if cp <= 0xA8FD:
        return True
    if cp < 0xA800:
        return False
    if cp <= 0xA925:
        return True
    if cp < 0xA803:
        return False
    if cp <= 0xA946:
        return True
    if cp < 0xA807:
        return False
    if cp <= 0xA97C:
        return True
    if cp < 0xA80C:
        return False
    if cp <= 0xA9B2:
        return True
    if cp < 0xA823:
        return False
    if cp <= 0xA9CF:
        return True
    if cp < 0xA840:
        return False
    if cp <= 0xA9E4:
        return True
    if cp < 0xA882:
        return False
    if cp <= 0xA9E6:
        return True
    if cp < 0xA8D0:
        return False
    if cp <= 0xA9EF:
        return True
    if cp < 0xA8F2:
        return False
    if cp <= 0xA9FE:
        return True
    if cp < 0xA8FB:
        return False
    if cp <= 0xAA36:
        return True
    if cp < 0xA8FD:
        return False
    if cp <= 0xAA43:
        return True
    if cp < 0xA90A:
        return False
    if cp <= 0xAA4B:
        return True
    if cp < 0xA930:
        return False
    if cp <= 0xAA6F:
        return True
    if cp < 0xA960:
        return False
    if cp <= 0xAA7A:
        return True
    if cp < 0xA984:
        return False
    if cp <= 0xAA7E:
        return True
    if cp < 0xA9B3:
        return False
    if cp <= 0xAAB1:
        return True
    if cp < 0xA9CF:
        return False
    if cp <= 0xAAB6:
        return True
    if cp < 0xA9E0:
        return False
    if cp <= 0xAABD:
        return True
    if cp < 0xA9E6:
        return False
    if cp <= 0xAABF:
        return True
    if cp < 0xA9E7:
        return False
    if cp <= 0xAAC2:
        return True
    if cp < 0xA9FA:
        return False
    if cp <= 0xAADD:
        return True
    if cp < 0xAA00:
        return False
    if cp <= 0xAAEA:
        return True
    if cp < 0xAA40:
        return False
    if cp <= 0xAAF4:
        return True
    if cp < 0xAA44:
        return False
    if cp <= 0xAB06:
        return True
    if cp < 0xAA60:
        return False
    if cp <= 0xAB0E:
        return True
    if cp < 0xAA7A:
        return False
    if cp <= 0xAB16:
        return True
    if cp < 0xAA7E:
        return False
    if cp <= 0xAB26:
        return True
    if cp < 0xAAB1:
        return False
    if cp <= 0xAB2E:
        return True
    if cp < 0xAAB5:
        return False
    if cp <= 0xAB5A:
        return True
    if cp < 0xAAB9:
        return False
    if cp <= 0xAB64:
        return True
    if cp < 0xAABE:
        return False
    if cp <= 0xAB67:
        return True
    if cp < 0xAAC2:
        return False
    if cp <= 0xABBF:
        return True
    if cp < 0xAADB:
        return False
    if cp <= 0xABE2:
        return True
    if cp < 0xAAE0:
        return False
    if cp <= 0xD7A3:
        return True
    if cp < 0xAAF2:
        return False
    if cp <= 0xD7C6:
        return True
    if cp < 0xAB01:
        return False
    if cp <= 0xD7FB:
        return True
    if cp < 0xAB09:
        return False
    if cp <= 0xFAD9:
        return True
    if cp < 0xAB11:
        return False
    if cp <= 0xFB06:
        return True
    if cp < 0xAB20:
        return False
    if cp <= 0xFB17:
        return True
    if cp < 0xAB28:
        return False
    if cp <= 0xFB1D:
        return True
    if cp < 0xAB30:
        return False
    if cp <= 0xFB36:
        return True
    if cp < 0xAB5C:
        return False
    if cp <= 0xFBB1:
        return True
    if cp < 0xAB65:
        return False
    if cp <= 0xFBC1:
        return True
    if cp < 0xAB70:
        return False
    if cp <= 0xFD3D:
        return True
    if cp < 0xABE3:
        return False
    if cp <= 0xFD3F:
        return True
    if cp < 0xAC00:
        return False
    if cp <= 0xFD8F:
        return True
    if cp < 0xD7B0:
        return False
    if cp <= 0xFDFB:
        return True
    if cp < 0xD7CB:
        return False
    if cp <= 0xFDFD:
        return True
    if cp < 0xF900:
        return False
    if cp <= 0xFEFC:
        return True
    if cp < 0xFB00:
        return False
    if cp <= 0xFE74:
        return True
    if cp < 0xFB13:
        return False
    if cp <= 0xFEFC:
        return True
    if cp < 0xFB1D:
        return False
    if cp <= 0xFF3A:
        return True
    if cp < 0xFB1F:
        return False
    if cp <= 0xFF5A:
        return True
    if cp < 0xFB50:
        return False
    if cp <= 0xFF9D:
        return True
    if cp < 0xFBC2:
        return False
    if cp <= 0xFF70:
        return True
    if cp < 0xFBD3:
        return False
    if cp <= 0xFF9D:
        return True
    if cp < 0xFD3E:
        return False
    if cp <= 0xFFBE:
        return True
    if cp < 0xFD50:
        return False
    if cp <= 0xFFBE:
        return True
    if cp < 0xFD92:
        return False
    if cp <= 0xFFCF:
        return True
    if cp < 0xFDF0:
        return False
    if cp <= 0x1000B:
        return True
    if cp < 0xFE70:
        return False
    if cp <= 0x10026:
        return True
    if cp < 0xFE74:
        return False
    if cp <= 0x1003A:
        return True
    if cp < 0xFE76:
        return False
    if cp <= 0x1003D:
        return True
    if cp < 0xFF21:
        return False
    if cp <= 0x1004D:
        return True
    if cp < 0xFF41:
        return False
    if cp <= 0x100FA:
        return True
    return False


def is_number(cp: Int) -> Bool:
    """True if Unicode code point cp is in General_Category N* (number)."""
    if cp < 0x0030:
        return False
    if cp <= 0x0039:
        return True
    if cp < 0x00B2:
        return False
    if cp <= 0x00B3:
        return True
    if cp < 0x00B9:
        return False
    if cp <= 0x00B9:
        return True
    if cp < 0x00BC:
        return False
    if cp <= 0x00BE:
        return True
    if cp < 0x0660:
        return False
    if cp <= 0x0669:
        return True
    if cp < 0x06F0:
        return False
    if cp <= 0x06F9:
        return True
    if cp < 0x07C0:
        return False
    if cp <= 0x07C9:
        return True
    if cp < 0x0966:
        return False
    if cp <= 0x096F:
        return True
    if cp < 0x09E6:
        return False
    if cp <= 0x09EF:
        return True
    if cp < 0x09F4:
        return False
    if cp <= 0x09F9:
        return True
    if cp < 0x0A66:
        return False
    if cp <= 0x0A6F:
        return True
    if cp < 0x0AE6:
        return False
    if cp <= 0x0AEF:
        return True
    if cp < 0x0B66:
        return False
    if cp <= 0x0B6F:
        return True
    if cp < 0x0BE6:
        return False
    if cp <= 0x0BF2:
        return True
    if cp < 0x0C66:
        return False
    if cp <= 0x0C6F:
        return True
    if cp < 0x0C78:
        return False
    if cp <= 0x0C7F:
        return True
    if cp < 0x0CE6:
        return False
    if cp <= 0x0CEF:
        return True
    if cp < 0x0D58:
        return False
    if cp <= 0x0D5E:
        return True
    if cp < 0x0D66:
        return False
    if cp <= 0x0D6F:
        return True
    if cp < 0x0DE6:
        return False
    if cp <= 0x0DEF:
        return True
    if cp < 0x0E50:
        return False
    if cp <= 0x0E59:
        return True
    if cp < 0x0ED0:
        return False
    if cp <= 0x0ED9:
        return True
    if cp < 0x0F20:
        return False
    if cp <= 0x0F33:
        return True
    if cp < 0x1040:
        return False
    if cp <= 0x1049:
        return True
    if cp < 0x1090:
        return False
    if cp <= 0x1099:
        return True
    if cp < 0x1946:
        return False
    if cp <= 0x194F:
        return True
    if cp < 0x19D0:
        return False
    if cp <= 0x19DA:
        return True
    if cp < 0x1A80:
        return False
    if cp <= 0x1A89:
        return True
    if cp < 0x1A90:
        return False
    if cp <= 0x1A99:
        return True
    if cp < 0x1B50:
        return False
    if cp <= 0x1B59:
        return True
    if cp < 0x1BB0:
        return False
    if cp <= 0x1BBF:
        return True
    if cp < 0x1C40:
        return False
    if cp <= 0x1C49:
        return True
    if cp < 0x1C50:
        return False
    if cp <= 0x1C59:
        return True
    if cp < 0x2070:
        return False
    if cp <= 0x2070:
        return True
    if cp < 0x2074:
        return False
    if cp <= 0x2079:
        return True
    if cp < 0x2080:
        return False
    if cp <= 0x2089:
        return True
    if cp < 0x2460:
        return False
    if cp <= 0x2473:
        return True
    if cp < 0x24EA:
        return False
    if cp <= 0x24FF:
        return True
    if cp < 0x2776:
        return False
    if cp <= 0x2793:
        return True
    if cp < 0x2CFD:
        return False
    if cp <= 0x2CFD:
        return True
    if cp < 0x3007:
        return False
    if cp <= 0x3007:
        return True
    if cp < 0x3021:
        return False
    if cp <= 0x3029:
        return True
    if cp < 0x3038:
        return False
    if cp <= 0x303A:
        return True
    if cp < 0x3192:
        return False
    if cp <= 0x3195:
        return True
    if cp < 0x3220:
        return False
    if cp <= 0x3247:
        return True
    if cp < 0x3248:
        return False
    if cp <= 0x3250:
        return True
    if cp < 0x3251:
        return False
    if cp <= 0x325F:
        return True
    if cp < 0x3280:
        return False
    if cp <= 0x328F:
        return True
    if cp < 0x3251:
        return False
    if cp <= 0x325F:
        return True
    if cp < 0xA620:
        return False
    if cp <= 0xA629:
        return True
    if cp < 0xA6E6:
        return False
    if cp <= 0xA6EF:
        return True
    if cp < 0xA830:
        return False
    if cp <= 0xA835:
        return True
    if cp < 0xA8D0:
        return False
    if cp <= 0xA8D9:
        return True
    if cp < 0xA900:
        return False
    if cp <= 0xA909:
        return True
    if cp < 0xA9D0:
        return False
    if cp <= 0xA9D9:
        return True
    if cp < 0xA9F0:
        return False
    if cp <= 0xA9F9:
        return True
    if cp < 0xAA50:
        return False
    if cp <= 0xAA59:
        return True
    if cp < 0xABF0:
        return False
    if cp <= 0xABF9:
        return True
    if cp < 0xFF10:
        return False
    if cp <= 0xFF19:
        return True
    return False
