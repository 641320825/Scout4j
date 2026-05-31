# Security Policy

## Supported scope

This skill provides workflow guidance for Java backend repositories. It should never contain credentials, private infrastructure details, customer data, or production-only operational instructions.

## Reporting a vulnerability

If you find a security issue in the skill guidance or helper scripts, open a private security report in the hosting repository or contact the maintainers through the project's documented security channel.

Include:

- affected file and section;
- why the guidance is unsafe;
- a minimal example if possible;
- suggested safer wording or behavior.

## Sensitive data rules

Do not contribute:

- API keys, tokens, cookies, or credentials;
- private hostnames, IPs, SSH aliases, or internal service names;
- production database names or customer data;
- proprietary architecture assumptions that do not generalize;
- logs containing private prompts, provider responses, or personal data.

## Safety boundaries

The skill should instruct agents to ask before:

- destructive writes;
- production data repair/backfill;
- schema migrations;
- public PRs/releases/posts;
- external service calls with side effects.

## Benchmark and evaluation data

Benchmark fixtures should be synthetic. If an evaluation result comes from private code, distill it into a generic lesson before adding it to the skill, or keep it outside the public package.
