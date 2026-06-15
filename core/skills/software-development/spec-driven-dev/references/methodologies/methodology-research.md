# Spec-Driven Development Research & Methodology Comparison

## Research Sources

### Specification by Example (SBE)
- **Source**: Martin Fowler, "Specification By Example" (2004)
- **URL**: https://martinfowler.com/bliki/SpecificationByExample.html
- **Key Insight**: Examples trigger abstractions in design teams while keeping abstractions grounded. Easier for non-technical stakeholders than pre/post conditions.
- **Quote**: "Specification By Example isn't enough — it forces you to do more to ensure everything is properly communicated."

### Behavior-Driven Development (BDD)
- **Source**: Cucumber Blog, "BDD vs TDD"
- **URL**: https://cucumber.io/blog/bdd/bdd-vs-tdd/
- **Key Insight**: BDD involves developer, test engineer, AND product manager creating concrete examples in Gherkin (Given/When/Then). Feature files become executable specifications.
- **Quote**: "BDD is merely the evolution of test-driven development."

### API Specification-First (OpenAPI/Swagger)
- **Source**: Swagger/OpenAPI Official Docs
- **URL**: https://swagger.io/docs/specification/about/
- **Key Insight**: Design-first approach — write OpenAPI spec first, then generate server stubs/client libraries. Swagger Codegen can generate boilerplate code from spec.
- **Tools**: Swagger Editor, Swagger UI, Swagger Codegen, Swagger Parser

### Design by Contract (DbC)
- **Source**: Martin Fowler, Eiffel
- **Key Insight**: Pre-conditions, post-conditions, and invariants define contracts at interfaces. More formal than SBE but harder to write for non-technical stakeholders.

## Methodology Comparison

| Methodology | Focus | Strength | Weakness | Best For |
|-------------|-------|----------|----------|----------|
| SBE | Concrete examples | Stakeholder communication | Incomplete alone | Requirements gathering |
| BDD | Behavior scenarios | Executable specs | Gherkin learning curve | Acceptance testing |
| API-First | Interface contracts | Code generation | API-only scope | REST API development |
| DbC | Pre/Post conditions | Formal verification | Hard to write | Critical interfaces |
| TDD | Unit tests | Code confidence | Developer-only | Implementation |

## Integration Patterns

### Spec → Code Flow (Current)
```
Spec (requirements.md)
  ↓ (developer reads)
Code Implementation
  ↓ (@spec_id annotation)
Traceability Matrix
```

### Spec → Code Flow (Enhanced)
```
Spec (with Example + Pre/Post)
  ↓ (generate.js template-based)
Code Implementation
  ↓ (@spec_id + acceptance criteria)
Automated Conformance Check
  ↓ (traceability: spec→test→code)
Full Traceability Matrix
```

## Gherkin Template (BDD Reference)

```gherkin
Feature: User Authentication
  As a user
  I want to sign in securely
  So that my data is protected

  Scenario: Valid credentials
    Given I am on the login page
    When I enter "user@example.com" and "password123"
    And I click "Sign In"
    Then I should see the dashboard
    And I should receive a 200 OK response
```

## OpenAPI Spec Example (API-First Reference)

```yaml
openapi: 3.0.0
info:
  title: User API
  version: 1.0.0
paths:
  /users/{id}:
    get:
      summary: Get user by ID
      parameters:
        - name: id
          in: path
          required: true
          schema:
            type: integer
      responses:
        '200':
          description: User found
        '404':
          description: User not found
```

## Design by Contract Pattern

```python
# Pre-condition example
def transfer_money(from_account, to_account, amount):
    assert amount > 0, "Amount must be positive"  # Pre-condition
    assert from_account.balance >= amount, "Insufficient funds"  # Pre-condition
    
    # Implementation
    from_account.balance -= amount
    to_account.balance += amount
    
    assert from_account.balance + to_account.balance == original_total  # Post-condition
```

## Session Notes (JOB-1488)

- Current spec-driven-dev has 7 reference files, 7 scripts, 4 templates
- Research identified 4 key methodologies to integrate: SBE, BDD, API-First, DbC
- Enhancement path: Add Example section to templates, strengthen conformance checks, improve traceability
