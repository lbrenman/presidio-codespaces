# Presidio in GitHub Codespaces

Run [Microsoft Presidio](https://github.com/microsoft/presidio) as a REST API instantly in GitHub Codespaces — no local setup required.

[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/lbrenman/presidio-codespaces)

### 📄 OpenAPI Specifications

Three separate specs are included in this repo — one per service:

| Service | Port | Spec | Swagger Editor |
|---|---|---|---|
| **Presidio Analyzer** | `5002` | [openapi-analyzer.json](./openapi-analyzer.json) | [Open in Swagger Editor](https://editor.swagger.io/?url=https://raw.githubusercontent.com/lbrenman/presidio-codespaces/main/openapi-analyzer.json) |
| **Presidio Anonymizer** | `5001` | [openapi-anonymizer.json](./openapi-anonymizer.json) | [Open in Swagger Editor](https://editor.swagger.io/?url=https://raw.githubusercontent.com/lbrenman/presidio-codespaces/main/openapi-anonymizer.json) |
| **Presidio Image Redactor** | `5003` | [openapi-image-redactor.json](./openapi-image-redactor.json) | [Open in Swagger Editor](https://editor.swagger.io/?url=https://raw.githubusercontent.com/lbrenman/presidio-codespaces/main/openapi-image-redactor.json) |

> The upstream combined spec (text services only) is also available via [Microsoft's ReDoc UI](https://microsoft.github.io/presidio/api-docs/api-docs.html).

---

## What is Presidio?

Presidio is an open-source PII (Personally Identifiable Information) detection and anonymization framework from Microsoft. It provides two core REST services:

| Service | Port | Purpose |
|---|---|---|
| **presidio-analyzer** | `5002` | Detect PII entities in text (names, emails, SSNs, phones, credit cards, etc.) |
| **presidio-anonymizer** | `5001` | Anonymize/redact detected PII (replace, mask, hash, encrypt, or redact) |
| **presidio-image-redactor** | `5003` | Detect and redact PII in images using OCR (PNG, JPEG, BMP, TIFF, DICOM) |

---

## Getting Started

### 1. Open in Codespaces

Click the badge above or go to **Code → Codespaces → New codespace** on this repo.

The devcontainer will automatically:
- Pull the official `mcr.microsoft.com/presidio-analyzer` and `mcr.microsoft.com/presidio-anonymizer` Docker images
- Start both services via Docker Compose
- Wait for health checks to pass and print a ready message
- Forward ports `5002` (analyzer), `5001` (anonymizer), and `5003` (image redactor) to your browser

> ⚠️ **Note:** The analyzer and image redactor images are large (~2 GB each) and include spaCy NLP models. First startup takes **3–6 minutes**. Subsequent starts are much faster.

### 2. Verify the services are running

```bash
bash test.sh
```

This runs a smoke test against both APIs and reports pass/fail for each check.

### 3. Try the APIs

#### Detect PII with the Analyzer

```bash
curl -X POST http://localhost:5002/analyze \
  -H "Content-Type: application/json" \
  -d '{
    "text": "Hi, I am John Smith. My email is john@example.com and my SSN is 078-05-1120.",
    "language": "en"
  }'
```

Example response:
```json
[
  { "entity_type": "PERSON",        "start": 10, "end": 20, "score": 0.85 },
  { "entity_type": "EMAIL_ADDRESS", "start": 33, "end": 49, "score": 1.0  },
  { "entity_type": "US_SSN",        "start": 63, "end": 74, "score": 0.85 }
]
```

#### Anonymize PII with the Anonymizer

```bash
curl -X POST http://localhost:5001/anonymize \
  -H "Content-Type: application/json" \
  -d '{
    "text": "Hi, I am John Smith. My email is john@example.com.",
    "anonymizers": {
      "DEFAULT": { "type": "replace" }
    },
    "analyzer_results": [
      { "start": 9,  "end": 19, "score": 0.85, "entity_type": "PERSON" },
      { "start": 33, "end": 49, "score": 1.0,  "entity_type": "EMAIL_ADDRESS" }
    ]
  }'
```

Example response:
```json
{
  "text": "Hi, I am <PERSON>. My email is <EMAIL_ADDRESS>.",
  "items": [...]
}
```

---

## VS Code REST Client

The file [`presidio.http`](./presidio.http) contains ready-to-run sample requests for the [REST Client extension](https://marketplace.visualstudio.com/items?itemName=humao.rest-client), which is automatically installed in the Codespace. Open the file and click **Send Request** above any request block.

Samples include:
- Analyze text for any PII
- Analyze for specific entity types only
- Anonymize with **replace** (default `<ENTITY_TYPE>` label)
- Anonymize with **mask** (e.g. `****1120`)
- Anonymize with **hash** (SHA-256)
- List all supported recognizers and entity types
- Redact PII from `samples/photo.png` (standard image with fake PII text)
- Redact PII from `samples/scan.dcm` (synthetic DICOM with fake PHI burned into pixels)

The `samples/` folder contains pre-built test files so the image redactor requests work out of the box.

---

## Key API Endpoints

### Analyzer (`http://localhost:5002`)

| Method | Path | Description |
|---|---|---|
| `GET` | `/health` | Health check |
| `POST` | `/analyze` | Detect PII in text |
| `GET` | `/recognizers` | List all recognizers |
| `GET` | `/supportedentities` | List all entity types |

### Anonymizer (`http://localhost:5001`)

| Method | Path | Description |
|---|---|---|
| `GET` | `/health` | Health check |
| `POST` | `/anonymize` | Anonymize text using analyzer results |
| `GET` | `/anonymizers` | List supported anonymizer operators |
| `GET` | `/deanonymize` | Reverse anonymization (for encrypt/decrypt) |

### Image Redactor (`http://localhost:5003`)

| Method | Path | Description |
|---|---|---|
| `GET` | `/health` | Health check |
| `POST` | `/redact` | Redact PII from a standard image (PNG, JPEG, BMP, TIFF) — returns redacted image |
| `POST` | `/redact-file` | Redact PII pixel data from a DICOM medical image — returns redacted DICOM file |



`PERSON`, `EMAIL_ADDRESS`, `PHONE_NUMBER`, `US_SSN`, `CREDIT_CARD`, `IBAN_CODE`, `IP_ADDRESS`, `LOCATION`, `DATE_TIME`, `NRP`, `US_DRIVER_LICENSE`, `US_PASSPORT`, `US_BANK_NUMBER`, `CRYPTO`, `MEDICAL_LICENSE`, and [many more](https://microsoft.github.io/presidio/supported_entities/).

---

## Running Locally (without Codespaces)

```bash
docker compose up -d
# Analyzer available at http://localhost:5002
# Anonymizer available at http://localhost:5001
```

---

## References

- [Presidio GitHub](https://github.com/microsoft/presidio)
- [Presidio Documentation](https://microsoft.github.io/presidio)
- [Presidio Docker Installation](https://microsoft.github.io/presidio/installation/#using-docker)
- [Presidio REST API Reference (ReDoc)](https://microsoft.github.io/presidio/api-docs/api-docs.html)
- [Analyzer OpenAPI Spec](./openapi-analyzer.json)
- [Anonymizer OpenAPI Spec](./openapi-anonymizer.json)
- [Image Redactor OpenAPI Spec](./openapi-image-redactor.json)
- [Presidio Image Redactor Documentation](https://microsoft.github.io/presidio/image-redactor/)
- [Supported Entities](https://microsoft.github.io/presidio/supported_entities/)
