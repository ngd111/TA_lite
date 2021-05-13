from tagger_utils cimport tagger_utils

def tagger_utils_addresult(_a, _b):
    tu = tagger_utils()
    return tu.addresult(_a, _b)

def tagger_utils_apply_com(_tokens, _dic):
    tu = tagger_utils()
    return tu._apply_compound_dictionary(_tokens, _dic)
