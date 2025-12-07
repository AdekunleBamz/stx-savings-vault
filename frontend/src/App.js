// frontend/src/App.js

import React, { useState } from 'react';
import { connect, authenticate, userSession } from '@stacks/connect';
import { StacksMocknet, StacksTestnet, StacksMainnet } from '@stacks/network';
import { callReadOnlyFunction, makeContractCall, StacksTransaction } from '@stacks/transactions';

const contractAddress = 'STYOURCONTRACTADDRESSHERE'; // Replace with your testnet/mainnet address
const contractName = 'stx-vault';
const functionNameDeposit = 'deposit-stx';
const functionNameWithdraw = 'withdraw-stx';

function App() {
  const [stxAmount, setStxAmount] = useState(0);
  const [lockDays, setLockDays] = useState(0);
  const [status, setStatus] = useState('Disconnected');
  const network = new StacksTestnet(); // Use StacksMainnet for mainnet deployment

  const appDetails = {
    appName: "STX Savings Vault",
    appIconSource: window.location.origin + "/logo.png",
  };

  const connectWallet = () => {
    authenticate({
      appDetails,
      onFinish: () => {
        window.location.reload();
      },
      onCancel: () => alert('Wallet connection cancelled'),
    });
  };

  const disconnectWallet = () => {
    userSession.signUserOut();
    window.location.reload();
  };

  const handleDeposit = async () => {
    if (!userSession.isUserSignedIn()) return alert('Please connect your wallet');
    setStatus('Depositing...');

    // Convert days to approximate blocks (approx 1 block every 10 mins)
    const blocks = lockDays * 6 * 24; 

    const functionArgs = [
      uintCV(stxAmount),
      uintCV(blocks),
    ];

    const options = {
      contractAddress,
      contractName,
      functionName: functionNameDeposit,
      functionArgs,
      appDetails,
      onFinish: (data) => {
        console.log('Transaction finished:', data.txId);
        setStatus('Deposit successful!');
      },
      onCancel: () => setStatus('Deposit cancelled'),
    };

    await makeContractCall(options);
  };

  const handleWithdraw = async () => {
    if (!userSession.isUserSignedIn()) return alert('Please connect your wallet');
    setStatus('Withdrawing...');

    const options = {
        contractAddress,
        contractName,
        functionName: functionNameWithdraw,
        functionArgs: [], // Withdraw function takes no arguments
        appDetails,
        onFinish: (data) => {
          console.log('Transaction finished:', data.txId);
          setStatus('Withdrawal successful!');
        },
        onCancel: () => setStatus('Withdrawal cancelled'),
      };

    await makeContractCall(options);
  };

  return (
    <div className="App">
      <header>
        <h1>STX Savings Vault</h1>
        {userSession.isUserSignedIn() ? (
          <button onClick={disconnectWallet}>Disconnect Wallet</button>
        ) : (
          <button onClick={connectWallet}>Connect Wallet</button>
        )}
      </header>
      <main>
        {userSession.isUserSignedIn() && (
          <div>
            <h2>Deposit STX</h2>
            <input
              type="number"
              placeholder="STX Amount"
              onChange={(e) => setStxAmount(e.target.value)}
            />
            <input
              type="number"
              placeholder="Lock Days"
              onChange={(e) => setLockDays(e.target.value)}
            />
            <button onClick={handleDeposit}>Deposit</button>
            <hr/>
            <h2>Withdraw STX</h2>
            <button onClick={handleWithdraw}>Withdraw</button>
          </div>
        )}
      </main>
      <footer>
        <p>Status: {status}</p>
      </footer>
    </div>
  );
}

export default App;