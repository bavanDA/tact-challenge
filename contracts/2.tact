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

struct Responce {
    sender: Address;
    msg: Slice;
}

contract Task2 with Deployable {
  admin: Address;

  init(admin: Address) {
    self.admin = admin;
  }
  
  receive(msg: Refund) {
    self.forward(msg.sender, DeployOk{queryId: msg.queryId}.toCell(), false, null);
  }

  receive(msg: Slice) {

    let ctx: Context = context();

    let res: Cell = Responce{ sender: ctx.sender, msg: msg }.toCell();

    if(ctx.sender != self.admin)
    {
        send(SendParameters{
        to: self.admin,
        value: 0, 
        mode: SendRemainingValue + SendIgnoreErrors, 
        body: res
        });
    }
  }
}

