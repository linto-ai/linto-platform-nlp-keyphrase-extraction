from spacy.tokens import Doc
from keybert import KeyBERT

class KeyphraseExtractor:
    """
    Wrapper class for KeyBERT.
    """
    def __init__(self, model, **kwargs):
        self.model = KeyBERT(model)
        self.kwargs = kwargs
        if not Doc.has_extension("keyphrases"):
            Doc.set_extension("keyphrases", default=[])

    def __call__(self, doc, **kwargs):
        runtime_kwargs = {}
        runtime_kwargs.update(self.kwargs)
        runtime_kwargs.update(kwargs)
        doc._.keyphrases = self.model.extract_keywords(doc.text, **runtime_kwargs)
        
        return doc