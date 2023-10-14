import { Blockchain, SandboxContract } from '@ton-community/sandbox';
import { Address, toNano,address } from 'ton-core';
import { Task2 } from '../wrappers/Task2';
import '@ton-community/test-utils';

describe('Task2', () => {
    let blockchain: Blockchain;
    let task2: SandboxContract<Task2>;
    let admin : Address

    beforeEach(async () => {
        blockchain = await Blockchain.create();
        admin = address("UQCD39VS5jcptHL8vMjEXrzGaRcCVYto7HUn4bpAOg8xqEBI");
        task2 = blockchain.openContract(await Task2.fromInit(admin));
        const deployer = await blockchain.treasury('deployer');
        const deployResult = await task2.send(
            deployer.getSender(),
            {
                value: toNano('0.05'),
            },
            {
                $$type: 'Deploy',
                queryId: 0n,
            }
        );
        expect(deployResult.transactions).toHaveTransaction({
            from: deployer.address,
            to: task2.address,
            deploy: true,
            success: true,
        });
    });

    it('test', async () => {
    });
});

