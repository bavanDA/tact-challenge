import "@stdlib/deploy";

/*
  TASK 2 - Proxy 
  Create a contract that forwards all received TONs
  to the admin contract (whose address is set in init_store).
  Message from this proxy contract to the admin contract should contain:
    - Address of user who sent original message (should be stored in the outcoming body's data/bits)
    - Original message that proxy smart contract received from user (should be stored in the outcoming body's first ref)
  Also, if admin contract decides to reject message (= if it sends to the proxy "Refund" message with opcode=0x44),
  proxy contract needs to forward all TONs (attached to Refund message) back to the user.
  User address will be provided in Refund message body as "sender".
*/

message(0x44) Refund {
  queryId: Int as uint64;
  sender: Address;
}

contract Task2 with Deployable {
  admin: Address; 

  init(admin: Address) {
    self.admin = admin;
  }
  
  receive(msg: Refund) {
    
    if(context().sender == self.admin)
    {
      self.forward(msg.sender, DeployOk{queryId: msg.queryId}.toCell(), false , null);
    }
    else
    {
      throw(110);
    }
  }

  receive(msg: Slice) {

    let sender_address: Address = context().sender;


    if(sender_address != self.admin)
    {
        send(SendParameters{
        to: self.admin,
        value: 0, 
        mode: SendRemainingValue, 
        body: beginCell().storeAddress(sender_address).storeRef(msg.asCell()).endCell()
        });
    }
  }
}

