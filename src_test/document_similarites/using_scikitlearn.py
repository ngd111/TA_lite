from sklearn.feature_extraction.text import TfidfVectorizer
from collections import defaultdict
from sklearn.metrics.pairwise import linear_kernel

documents = ["Human machine interface for lab abc computer applications",
        "A survey of user opinion of computer system response time",
        "The EPS user interface management system",
        "System and human system engineering testing of EPS",
        "Relation of user perceived response time to error measurement",
        "The generation of random binary unordered trees",
        "The intersection graph of paths in trees",
        "Graph minors IV Widths of trees and well quasi ordering",
        "Graph minors A survey"]

stoplist = set('for a of the and to in'.split())

vectorizer = TfidfVectorizer(min_df=2, analyzer='word', stop_words=list(stoplist))
tfidf = vectorizer.fit_transform(documents)
len(vectorizer.vocabulary_) # 12 features


new_document = []
new_document.append("Human computer interaction")   # 비교할 문장
tfidf_new = vectorizer.transform(new_document)

cosine_similarities = linear_kernel(tfidf_new, tfidf).flatten()
print(cosine_similarities)

# find top 5 documents
related_docs_indices = cosine_similarities.argsort()[:-6:-1]
cosine_similarities[related_docs_indices]

# query top 5 documents original sentences(except zero value similarity docs)
for idx in related_docs_indices:
    if cosine_similarities[idx] > 0:
        print idx, cosine_similarities[idx], documents[idx]

