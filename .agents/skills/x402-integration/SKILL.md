---
name: x402-integration
description: "Machine-to-machine crypto payments via Coinbase x402 protocol — USDC on Base, agent wallets, spending limits. Use when implementing agent-to-agent payments, autonomous transactions, or crypto payment gateways. Triggers on 'x402', 'agent wallet', 'machine payment', 'usdc', 'crypto payment'."
triggers: ["x402", "agent wallet", "machine payment", "usdc", "crypto payment", "autonomous payment", "coinbase protocol"]
tags: [engineering, backend, payments, crypto, agent-economy]
department: engineering
---

# x402 Integration — Machine-to-Machine Crypto Payments

Implementation patterns for the Coinbase x402 protocol — HTTP 402-based agent-to-agent payments using USDC on Base (Ethereum L2). Derived from a production implementation (6 files, `src/services/x402/`).

## Protocol Overview

x402 extends HTTP with native payment capabilities. When a server requires payment, it returns HTTP 402 with payment instructions. The client (agent) signs a USDC transfer authorization and resubmits the request with payment proof.

```
Agent sends request
    │
    v
Server returns HTTP 402 Payment Required
  Headers: X-Payment-Amount, X-Payment-Recipient, X-Payment-Network
    │
    v
Agent creates EIP-712 typed signature
    │
    v
Agent resubmits request with X-Payment-Proof header
    │
    v
Server validates signature on-chain → processes request
```

## Agent Wallet Generation

Each agent instance gets a deterministic Ethereum wallet:

```typescript
import { generatePrivateKey, privateKeyToAccount } from 'viem/accounts';
import { createWalletClient, http } from 'viem';
import { base } from 'viem/chains';

// One wallet per agent instance
function createAgentWallet(agentId: string): AgentWallet {
  // Option A: Deterministic from agent identity
  const privateKey = deriveKey(agentId, masterSeed);
  
  // Option B: Random, persisted in agent config
  const privateKey = generatePrivateKey();
  
  const account = privateKeyToAccount(privateKey);
  const client = createWalletClient({
    account,
    chain: base,
    transport: http(),
  });
  
  return {
    address: account.address,
    client,
    // NEVER expose privateKey in logs, responses, or memory
  };
}
```

### Key Storage

```
Production:  OS keychain (macOS Keychain, Linux Secret Service)
Development: Encrypted file (~/.agent-wallets/encrypted.json)
Testing:     Environment variable (AGENT_WALLET_KEY) — test networks only
CI/CD:       Vault/KMS (HashiCorp Vault, AWS KMS, GCP Secret Manager)
```

**Hard rule:** Private keys never appear in: logs, console output, error messages, memory files, tool results, conversation context, git commits.

## Safety Mechanisms

### Spending Limits

```typescript
interface SpendingLimits {
  perRequest: number;   // Default: $0.10 — single transaction cap
  perSession: number;   // Default: $5.00 — session-scoped cumulative cap
  perDay: number;       // Default: $50.00 — rolling 24h cap
  perMonth: number;     // Default: $500.00 — calendar month cap
}

// Enforcement
function canSpend(amount: number, limits: SpendingLimits, ledger: TransactionLedger): boolean {
  if (amount > limits.perRequest) return false;
  if (ledger.sessionTotal + amount > limits.perSession) return false;
  if (ledger.dayTotal + amount > limits.perDay) return false;
  if (ledger.monthTotal + amount > limits.perMonth) return false;
  return true;
}
```

### Transaction Ledger

Every payment attempt is logged (even failed ones):

```typescript
interface TransactionRecord {
  timestamp: string;        // ISO 8601
  agentId: string;          // Which agent initiated
  recipient: string;        // Ethereum address
  amount: number;           // USD value
  network: string;          // 'base' | 'base-sepolia' | 'ethereum'
  txHash?: string;          // On-chain hash if successful
  status: 'pending' | 'confirmed' | 'failed' | 'rejected';
  reason?: string;          // Why it was rejected/failed
  requestUrl: string;       // What the payment was for
}
```

### Pre-Payment Validation

Before signing any payment:

1. **Amount check** — Within per-request limit?
2. **Cumulative check** — Within session/day/month limits?
3. **Recipient check** — Is the recipient in the known-services allowlist?
4. **Network check** — Correct chain ID? (Prevent mainnet spend on test intent)
5. **Balance check** — Sufficient USDC balance?
6. **Duplicate check** — Same request + amount within 60 seconds? (Prevent double-pay)

## Signature Scheme

### EIP-712 Typed Data

```typescript
const domain = {
  name: 'USD Coin',
  version: '2',
  chainId: 8453,  // Base mainnet
  verifyingContract: USDC_CONTRACT_ADDRESS,
};

const types = {
  TransferWithAuthorization: [
    { name: 'from', type: 'address' },
    { name: 'to', type: 'address' },
    { name: 'value', type: 'uint256' },
    { name: 'validAfter', type: 'uint256' },
    { name: 'validBefore', type: 'uint256' },
    { name: 'nonce', type: 'bytes32' },
  ],
};
```

### EIP-3009 TransferWithAuthorization

Gasless USDC transfers — the recipient (server) submits the transaction and pays gas. The agent only signs, never pays gas directly.

```typescript
async function createPaymentProof(
  wallet: AgentWallet,
  recipient: string,
  amount: bigint,
): Promise<string> {
  const nonce = randomBytes(32);
  const validAfter = 0n;
  const validBefore = BigInt(Math.floor(Date.now() / 1000) + 3600); // 1h deadline
  
  const signature = await wallet.client.signTypedData({
    domain,
    types,
    primaryType: 'TransferWithAuthorization',
    message: {
      from: wallet.address,
      to: recipient,
      value: amount,
      validAfter,
      validBefore,
      nonce,
    },
  });
  
  return encodePaymentProof({ signature, nonce, validAfter, validBefore });
}
```

## Supported Networks

| Network | Chain ID | USDC Contract | Use Case |
|---------|----------|---------------|----------|
| Base | 8453 | `0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913` | Production |
| Base Sepolia | 84532 | `0x036CbD53842c5426634e7929541eC2318f3dCF7e` | Testing |
| Ethereum | 1 | `0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48` | High-value |
| Ethereum Sepolia | 11155111 | `0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238` | Testing |

**Default:** Base (lowest gas, fastest confirmation, same USDC).

## Implementation Pattern

### Server Side (Receiving Payments)

```typescript
// Middleware for x402-protected endpoints
function requirePayment(amount: number) {
  return async (req: Request, res: Response, next: NextFunction) => {
    const proof = req.headers['x-payment-proof'];
    
    if (!proof) {
      return res.status(402).json({
        error: 'Payment Required',
        amount,
        recipient: SERVER_WALLET_ADDRESS,
        network: 'base',
        currency: 'USDC',
      });
    }
    
    const valid = await verifyPaymentProof(proof, amount, SERVER_WALLET_ADDRESS);
    if (!valid) {
      return res.status(402).json({ error: 'Invalid payment proof' });
    }
    
    // Submit the transfer on-chain
    const txHash = await submitTransfer(proof);
    req.paymentTxHash = txHash;
    next();
  };
}
```

### Client Side (Agent Making Payments)

```typescript
async function paidRequest(url: string, options: RequestInit = {}): Promise<Response> {
  // First attempt without payment
  const res = await fetch(url, options);
  
  if (res.status !== 402) return res;
  
  // Parse payment requirements
  const { amount, recipient, network } = await res.json();
  
  // Safety checks
  if (!canSpend(amount, limits, ledger)) {
    throw new SpendingLimitError(amount, limits);
  }
  
  // Create payment proof
  const proof = await createPaymentProof(wallet, recipient, parseUnits(amount, 6));
  
  // Retry with payment
  const paidRes = await fetch(url, {
    ...options,
    headers: { ...options.headers, 'X-Payment-Proof': proof },
  });
  
  // Log transaction
  ledger.record({ amount, recipient, network, status: 'confirmed', requestUrl: url });
  
  return paidRes;
}
```

## Application Scenarios

### Agent Marketplace

Agents buy/sell capabilities from each other:
- Data agent sells market data feeds ($0.01/request)
- Analysis agent sells pattern recognition ($0.05/analysis)
- Execution agent charges for trade placement ($0.02/trade)

### LP Gateway Monetization

your runtime charges per-API-call:
- Free tier: 100 calls/day (no wallet needed)
- Paid tier: unlimited, $0.001/call via x402
- Premium endpoints: $0.01-0.10/call (complex analysis, GPU inference)

### Data Marketplace

Agents autonomously purchase data:
- Market data feeds (real-time quotes, historical bars)
- Research reports (summarized, relevance-scored)
- Signal subscriptions (alerts, pattern detections)

### Micro-SaaS Billing

Any developer monetizes their agent's capabilities:
- Expose capability as HTTP endpoint
- Add `requirePayment()` middleware
- Agent callers pay per-use, no subscription needed

## Quality Gates

- [ ] Private keys never appear in logs, memory, or conversation context
- [ ] Spending limits enforced at all four levels (request/session/day/month)
- [ ] Every transaction logged with full audit trail
- [ ] Pre-payment validation covers: amount, cumulative, recipient, network, balance, duplicate
- [ ] EIP-712 signatures include deadline (validBefore) — no indefinite authorizations
- [ ] Network selection matches environment (never mainnet in dev/test)
- [ ] Recipient allowlist prevents payments to unknown addresses
- [ ] Failed transactions include actionable error messages

## Security Considerations

- **Key isolation**: One wallet per agent instance. Compromised agent cannot drain other agents.
- **Limit enforcement**: Server-side limits in addition to client-side (defense in depth).
- **Nonce management**: Random nonces prevent replay attacks. EIP-3009 nonces are single-use.
- **Deadline enforcement**: All authorizations expire (1h default). No indefinite payment proofs.
- **Allowlist over blocklist**: Only pay known recipients, not "pay anyone except blocklisted."

## When NOT to Use

- Not for user-facing payment flows (use Stripe, traditional payment processors)
- Not for fiat currency transactions (x402 is crypto-native, USDC only)
- Not for high-value transactions without human approval (use spending limits + confirmation)
- Not for networks without USDC support
- Not when gas costs exceed payment value (batch small payments instead)

## Related Skills

- `auth-patterns` — security (authentication for the API layer around payments)
- `api-design-principles` — engineering (API design for payment-protected endpoints)
- `harness-engineering` — engineering (integrating x402 into agent harness)

## Platform Support

Works with: Claude Code, any agent framework with HTTP client capabilities.

## Dependencies

- `viem` — Ethereum interaction library (wallet, signing, contracts)
- USDC contract ABI (EIP-3009 TransferWithAuthorization)
- RPC endpoint for Base (Alchemy, Infura, or public)
