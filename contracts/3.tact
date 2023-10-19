import "@stdlib/deploy";

/*
  TASK 3 - DEX
  Create a simple jetton dex contract that trades one pair of jettons: A and B.
  The price of jettons depends on the amount of jettons that smart contract has.
  Therefore, the smart contract needs to keep track of how much jettons it has.
  
  Price for the jetton A in swap B->A should be calculated by formula "amountOfJettonAOnContract * decimal / amountOfJettonBOnContract".
  Token prices must be decimalized for accuracy, so it is the prices that must be adjusted to decimal 1e9.
  Decimals are only needed for price accuracy. It should be set as 1e9.
  So, if smart contract has 10 of jetton A and 2 of jetton B, then after sending 1 jetton B you should receive 5 of jettons A.

  Example formula for amountOfAJettonToSend in B->A swap will be
  (amountOfJettonAOnContract * decimal / amountOfJettonBOnContract) * amountOfTokenBToSwap / decimal

  If smart contract pool doesn't have enough jettons to trade,
  then it should send incoming jettons back to the user. For a clearer explanation,
  let's look at the example we described above (smart contract has 10 of jetton A and 2 of jetton B).
  If user will send 3 jettons B, smart contract should reject the message (because contract does not have 3 * 5 = 15 jettons A)
  and send 3 jettons B back to the user.

  If smart contract receives a different jetton (neither A nor B) then throw an error.

  Implement a getter that returns the number of jettons in the pool and
  one more to get the price of jetton A or jetton B.
  Getters' behavior with incorrect parameter (address other than that of jetton A or B)
  is undefined (there are no such tests).
  
  Note:
  Admin can add jettons A and B just by sending them to the smart contract (we need to add initial supply to the pool for it to be functional).
  To be exact: any jettons (A or B) received from the admin are "added". Admin can't swap.
*/


message(0x7362d09c) TokenNotification {
    queryId: Int as uint64;
    amount: Int as coins;
    from: Address;
    forwardPayload: Slice as remaining;
}

// To simplify the testing process and the specificity of the messages being sent, we decided to add clear default values in this transaction
message(0xf8a7ea5) TokenTransfer {
     queryId: Int as uint64; // should be 0
     amount: Int as coins; // should be amount of jettons to send
     destination: Address; // should be user address / TokenNotification.from
     responseDestination: Address?; // should be myAddress()
     customPayload: Cell?; // should be null
     forwardTonAmount: Int as coins; // should be ton("0.01")
     forwardPayload: Slice as remaining; // should be emptySlice()
}

contract Task3 with Deployable {
  owner: Address;
  aAmount: Int;
  bAmount: Int;
  jettonAddressA: Address;
  jettonAddressB: Address;
  decimal: Int;

  init(admin: Address, newJettonAddressA: Address, newJettonAddressB: Address) {
    self.owner = admin;
    self.jettonAddressA = newJettonAddressA;
    self.jettonAddressB = newJettonAddressB;
    self.aAmount = 0;
    self.bAmount = 0;
    self.decimal = 1000000000;
  }

  receive(msg: TokenNotification) {

      let ctx: Context = context();
      let amountOfJettonAOnContract: Int = self.aAmount;
      let amountOfJettonBOnContract: Int = self.bAmount;

      let jettonAddressA: Address = self.jettonAddressA;
      let jettonAddressB: Address = self.jettonAddressB;


      if(ctx.sender != jettonAddressA && ctx.sender != jettonAddressB)
      {
        throw(100);
      }

      if(msg.from == self.owner)
      {
        if(ctx.sender == jettonAddressA)
        {
          amountOfJettonAOnContract = amountOfJettonAOnContract + msg.amount;
          self.aAmount = amountOfJettonAOnContract;

          return;
        }
        
        if(ctx.sender == jettonAddressB)
        {
          amountOfJettonBOnContract = amountOfJettonBOnContract + msg.amount;
          self.bAmount = amountOfJettonBOnContract;   
          return;
        }
      }

    if(amountOfJettonAOnContract> 0 && amountOfJettonBOnContract> 0 ) 
    {
          if(ctx.sender == jettonAddressA)
          {
              let jetton_amount_b: Int = (amountOfJettonBOnContract * self.decimal / amountOfJettonAOnContract) * msg.amount / self.decimal;

              if(jetton_amount_b <= amountOfJettonBOnContract)
              {   
        
                send(SendParameters{
                    to: jettonAddressB, 
                    value: 0,
                    mode: SendRemainingValue + SendIgnoreErrors,
                    body: TokenTransfer{ queryId: 0,
                                        amount: jetton_amount_b, 
                                        destination:  msg.from,
                                        responseDestination: myAddress(), 
                                        customPayload: null,
                                        forwardTonAmount:  ton("0.01"),
                                        forwardPayload: emptySlice() }.toCell() });

                
                amountOfJettonAOnContract = amountOfJettonAOnContract +  msg.amount;
                amountOfJettonBOnContract = amountOfJettonBOnContract - jetton_amount_b;


                self.aAmount = amountOfJettonAOnContract;
                self.bAmount = amountOfJettonBOnContract;                         

                return;

              }          
          }
     
          let jetton_amount_a: Int = (amountOfJettonAOnContract  * self.decimal / amountOfJettonBOnContract ) * msg.amount /self.decimal;

          if(jetton_amount_a <= amountOfJettonAOnContract )
          {
                
            send(SendParameters{
                      to: jettonAddressA, 
                      value: 0,
                      mode: SendRemainingValue + SendIgnoreErrors,
                      body:  TokenTransfer{ queryId: 0,
                                        amount: jetton_amount_a, 
                                        destination:  msg.from,
                                        responseDestination: myAddress(), 
                                        customPayload: null,
                                        forwardTonAmount:  ton("0.01"),
                                        forwardPayload: emptySlice() }.toCell() });


            amountOfJettonBOnContract = amountOfJettonBOnContract +  msg.amount;
            amountOfJettonAOnContract = amountOfJettonAOnContract - jetton_amount_a;

            self.bAmount = amountOfJettonBOnContract;
            self.aAmount = amountOfJettonAOnContract;

            return;
          }
      }
  

      send(SendParameters{
          to: ctx.sender, 
          value: 0,
          bounce: false,
          mode: SendRemainingValue + SendIgnoreErrors,
          body: TokenTransfer{ queryId: 0,
                               amount: msg.amount, 
                              destination:  msg.from,
                              responseDestination: myAddress(), 
                              customPayload: null,
                              forwardTonAmount:  ton("0.01"),
                              forwardPayload: emptySlice() }.toCell() });


  } 
  
  get fun price(jetton: Address): Int { 

    let amountOfJettonAOnContract: Int = self.aAmount;
    let amountOfJettonBOnContract: Int = self.bAmount;

    if(jetton == self.jettonAddressA)
    {
      return amountOfJettonAOnContract * self.decimal / amountOfJettonBOnContract;
    }
    
    if(jetton == self.jettonAddressB)
    {
      return amountOfJettonBOnContract * self.decimal / amountOfJettonAOnContract;
    }

     return 0; 
  }
  
  get fun balance(jetton: Address): Int { 

        if(jetton == self.jettonAddressA)
        {
          return self.aAmount;
        }
        
        if (jetton == self.jettonAddressB)
        {
          return self.bAmount;
        }
        
        return 0; 
  }
}