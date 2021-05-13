#! /usr/bin/python
from keyword_extraction import keyword_extraction
from collocation_extraction import collocation_extraction
from konlpy.utils import pprint


keywords_ext = keyword_extraction()
collocation_ext = collocation_extraction()

def _read_compound_words_dictionary():
    try:
        f = open("./com_dict_sample.txt", "r")
    except IOError as e:
        f.close()
        return {}

    compound_text = f.read()
    dict = {}
    for d in [c.strip() for c in compound_text.split(",")]:
        dict_members = d.split(":")
        if len(dict_members) != 2:
            raise ValueError("compound text data is not valid")
        key_list = []
        for m in dict_members[0].split("+"):
            key_list.append(unicode(m))
        dict_key = tuple(key_list)
        dict_value = dict_members[1]
        dict[dict_key] = unicode(dict_value)

    return dict


keywords_ext.document_frequency = (2, 0.9)

c_dict = _read_compound_words_dictionary()

f = open("../data/news_data/news0.txt", "r")
text = f.readlines()
#text = unicode(text)
f.close()
r_text = []
for t in text:
    temp_t = t.replace("\n", "")
    if len(temp_t) > 0:
        r_text.append(temp_t)

keywords = keywords_ext.extraction(_sents=r_text, _compound_words_dictionary=c_dict)
print('\n--------- Tokens after tagging  ------------')
pprint(keywords_ext.read_tokens(0))
print('\n--------- End of tokens ------- ------------')
print('\n--------- Keywords    ----------------------')
pprint(keywords)
print('\n--------- End of keywords ------------------')

col = collocation_ext.extraction(keywords_ext.read_tokens(), 2)
print('\n--------- Collocation ----------------------')
for k, v in col.iteritems():
    print "", k, "=> ", ", ".join(v)
print('\n--------- End of collocation ---------------\n')
    
#pprint(col)
