# linto-platform-nlp-keyphrase-extraction

## Description
This repository is for building a Docker image for LinTO's NLP service: Keyphrase Extraction on the basis of [linto-platform-nlp-core](https://github.com/linto-ai/linto-platform-nlp-core), can be deployed along with [LinTO stack](https://github.com/linto-ai/linto-platform-stack) or in a standalone way (see Develop section in below).

linto-platform-nlp-keyphrase-extraction is backed by [spaCy](https://spacy.io/) v3.0+ featuring transformer-based pipelines, thus deploying with GPU support is highly recommeded for inference efficiency.

LinTo's NLP services adopt the basic design concept of spaCy: [component and pipeline](https://spacy.io/usage/processing-pipelines), componets are decoupled from the service and can be easily re-used in other projects, components are organised into pipelines for realising specific NLP tasks. 

This service uses [FastAPI](https://fastapi.tiangolo.com/) to serve custom spaCy's components as pipelines:
- `kpe`: Keyphrase Extraction

## Usage

See documentation : [https://doc.linto.ai](https://doc.linto.ai)

## Deploy

With our proposed stack [https://github.com/linto-ai/linto-platform-stack](https://github.com/linto-ai/linto-platform-stack)

# Develop

## Build and run
1 Create a named volume for storaging models.
```bash
sudo docker volume create linto-platform-nlp-assets
```

2 Download models into `assets/` on the host machine, make sure that `git-lfs`: [Git Large File Storage](https://git-lfs.github.com/) is installed and availble at `/usr/local/bin/git-lfs`.
```bash
cd linto-platform-nlp-keyphrase-extraction/
bash scripts/download_models.sh
```

3 Copy downloaded models into created volume `linto-platform-nlp-assets`
```bash
sudo docker container create --name cp_helper -v linto-platform-nlp-assets:/root hello-world
sudo docker cp assets/* cp_helper:/root
sudo docker rm cp_helper
```

4 Build image
```bash
sudo docker build --tag lintoai/linto-platform-keyphrase-extraction:latest .
```

5 Run container (with GPU), make sure that [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html#installing-on-ubuntu-and-debian) and GPU driver are installed.
```bash
sudo docker run --gpus all \
--rm -d -p 80:80 \
-v linto-platform-nlp-assets:/app/assets:ro \
--env APP_LANG="fr en" \
lintoai/linto-platform-keyphrase-extraction:latest
```
<details>
  <summary>Check running with CPU only setting</summary>
  
  ```bash
sudo docker run \
--rm -d -p 80:80 \
-v linto-platform-nlp-assets:/app/assets:ro \
--env APP_LANG="fr en" \
lintoai/linto-platform-keyphrase-extraction:latest
  ```
</details>
To specify running language of the container, modify APP_LANG="fr en", APP_LANG="fr", etc.

To lanche with multiple workers, add `--workers INTEGER` in the end of the above command.

6 Navigate to `http://localhost/docs` or `http://localhost/redoc` in your browser, to explore the REST API interactively. See the examples for how to query the API.


## Specification for `http://localhost/kpe/{lang}`

### Supported languages
| {lang} | Model | Size |
| --- | --- | --- |
| `en` | [sentence-transformers/all-MiniLM-L6-v2](https://huggingface.co/sentence-transformers/all-MiniLM-L6-v2) | 80 MB |
| `fr` | [sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2](https://huggingface.co/sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2) | 418 MB |

### Request
```json
{
  "articles": [
    {
      "text": "Apple Inc. is an American multinational technology company that specializes in consumer electronics, computer software and online services."
    },
    {
      "text": "Unsupervised learning is a type of machine learning in which the algorithm is not provided with any pre-assigned labels or scores for the training data. As a result, unsupervised learning algorithms must first self-discover any naturally occurring patterns in that training data set."
    }
  ]
}
```

### Response
```json
{
  "kpe": [
    {
      "text": "Apple Inc. is an American multinational technology company that specializes in consumer electronics, computer software and online services.",
      "keyphrases": [
        {
          "text": "apple",
          "score": 0.6539
        },
        {
          "text": "inc",
          "score": 0.3941
        },
        {
          "text": "company",
          "score": 0.2985
        },
        {
          "text": "multinational",
          "score": 0.2635
        },
        {
          "text": "electronics",
          "score": 0.2143
        }
      ]
    },
    {
      "text": "Unsupervised learning is a type of machine learning in which the algorithm is not provided with any pre-assigned labels or scores for the training data. As a result, unsupervised learning algorithms must first self-discover any naturally occurring patterns in that training data set.",
      "keyphrases": [
        {
          "text": "unsupervised",
          "score": 0.6663
        },
        {
          "text": "learning",
          "score": 0.3155
        },
        {
          "text": "algorithms",
          "score": 0.3128
        },
        {
          "text": "algorithm",
          "score": 0.2494
        },
        {
          "text": "patterns",
          "score": 0.2476
        }
      ]
    }
  ]
}
```

### Component configuration
This is a component wrapped on the basis of [KeyBERT](https://github.com/MaartenGr/KeyBERT).

| Parameter | Type | Default value | Description |
| --- | --- | --- | --- |
| candidates | List[str] | null | Candidate keywords/keyphrases to use instead of extracting them from the document(s) |
| diversity | Float | 0.5 | The diversity of results between 0 and 1 if use_mmr is True |
| keyphrase_ngram_range | Tuple[int, int] | [1,1] | Length, in words, of the extracted keywords/keyphrases |
| min_df | int | 1 | Minimum document frequency of a word across all documents if keywords for multiple documents need to be extracted |
| nr_candidates | int | 20 | The number of candidates to consider if use_maxsum is set to True |
| seed_keywords | List[str] | null | Seed keywords that may guide the extraction of keywords by steering the similarities towards the seeded keywords |
| stop_words | Union[str, List[str]] | null | Stopwords to remove from the document |
| top_n | int | 5 | Return the top n keywords/keyphrases |
| use_maxsum | bool | false | Whether to use Max Sum Similarity for the selection of keywords/keyphrases |
| use_mmr | bool | false | Whether to use Maximal Marginal Relevance (MMR) for the selection of keywords/keyphrases |

Component's config can be modified in [`components/config.cfg`](components/config.cfg) for default values, or on the per API request basis at runtime:

```json
{
  "articles": [
    {
      "text": "Unsupervised learning is a type of machine learning in which the algorithm is not provided with any pre-assigned labels or scores for the training data. As a result, unsupervised learning algorithms must first self-discover any naturally occurring patterns in that training data set."
    }
  ],
  "component_cfg": {
    "kpe": {"keyphrase_ngram_range": [2,2], "top_n": 1}
  }
}
```

```json
{
  "kpe": [
    {
      "text": "Unsupervised learning is a type of machine learning in which the algorithm is not provided with any pre-assigned labels or scores for the training data. As a result, unsupervised learning algorithms must first self-discover any naturally occurring patterns in that training data set.",
      "keyphrases": [
        {
          "text": "unsupervised learning",
          "score": 0.7252
        }
      ]
    }
  ]
}
```

### Advanced usage
For advanced usage, such as Max Sum Similarity and Maximal Marginal Relevance for diversifying extraction results, please refer to the documentation of [KeyBERT](https://maartengr.github.io/KeyBERT/guides/quickstart.html#usage) and [medium post](https://towardsdatascience.com/keyword-extraction-with-bert-724efca412ea) to know how it works.