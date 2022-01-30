// SPDX-License-Identifier: AFL-3.0
pragma solidity ^0.7.0;
    
contract TaxiBusiness {

    struct Participant{
        address payable addressOfParticipant;
        uint balanceOfParticipant;
    }

    struct TaxiDriver{
        address payable addressOfDriver;
        uint salary;
        uint approvalStateForDriver;
        uint fireStateForDriver;
    }   

    uint balanceOfDriver;
    address payable addressOfCarDealer;
    uint[] public temporaryBalanceArray;    
    bool driverIsProposed;
    uint totalProfitForOneParticipant;
    uint contractBalance;
    uint maintenanceAndTaxPrice;  
    uint participationFee; 
    uint numberOfParticipants;
    uint currentLength;
    bool oneMonthPassed;
    uint monthsPassed;

    mapping(address => uint) public participantId;  
    mapping(address => bool) isApprovedCarBefore;
    mapping(address => bool) isApprovedSellBefore;
    mapping(address => bool) isApprovedDriverBefore;
    mapping(address => bool) isApprovedFireBefore;

    struct OwnedCar{
        uint32 ownerCarID;
    }

    struct ProposedCar{
        uint proposedCarID;
        uint proposedPrice;
        uint offerValidTimeForCar;
        uint approvalStateForCar;
        uint startTime;
    }

    struct ProposedRepurchase{
        uint ownedCarID;
        uint proposedRepurchasePrice;
        uint offerValidTimeForRepurchase;
        uint approvalStateForRepurchase;
        uint repurchaseTime;

    }

    
    // Creating initials
    ProposedRepurchase public propRepurchase;
    ProposedCar public propCar;
    TaxiDriver public driver;
    TaxiDriver public newDriver;
    Participant public participant;
    constructor (){
        temporaryBalanceArray[0] = 0;
        maintenanceAndTaxPrice = 10 ; // 10 ether
        participationFee = 100; // 100 ether
        addressOfCarDealer ;
    }

    function join() public payable {
        currentLength = temporaryBalanceArray.length;
        participantId[msg.sender] = currentLength;
        // payable(msg.sender).call{value: -(participationFee)}("");
        numberOfParticipants++;
    }

    function carProposeToBusiness(uint carID, uint price, uint offerValidTimeForCar) external {
        require(msg.sender == addressOfCarDealer);
        
        propCar = ProposedCar({
            proposedCarID : carID,
            proposedPrice : price,
            offerValidTimeForCar : offerValidTimeForCar,
            approvalStateForCar : 0,
            startTime: block.timestamp
        });
    }

    function approvePurchaseCar() external {
        require(isApprovedCarBefore[msg.sender] == false); // Each participant can increment once
        propCar.approvalStateForCar++;
        
        isApprovedCarBefore[msg.sender] = true;
        if(numberOfParticipants / 2 < propCar.approvalStateForCar){
            this.purchaseCar();
        } 
    }

    function purchaseCar() external {
        if(propCar.offerValidTimeForCar + propCar.startTime > block.timestamp){      
            addressOfCarDealer.call{value: propCar.proposedPrice}("");
        }
    }

    function repurchaseCarPropose(uint carID,uint price, uint offerValidTimeForRepurchase) external {
        require(msg.sender == addressOfCarDealer); 

        propRepurchase = ProposedRepurchase({
            ownedCarID: carID,
            proposedRepurchasePrice : price,
            offerValidTimeForRepurchase: offerValidTimeForRepurchase,
            approvalStateForRepurchase: 0,
            repurchaseTime: block.timestamp
        });
    }

    function approveSellProposal() external {
        require(isApprovedSellBefore[msg.sender] == false); // Each participant can increment once
        propRepurchase.approvalStateForRepurchase++;
        
        isApprovedSellBefore[msg.sender] = true;
        if(numberOfParticipants / 2 < propRepurchase.approvalStateForRepurchase){
            this.repurchaseCar();

        } 
    }

    function repurchaseCar() external {
        if(propRepurchase.offerValidTimeForRepurchase + propRepurchase.repurchaseTime > block.timestamp){
            addressOfCarDealer.call{value: propRepurchase.proposedRepurchasePrice}("");
        }
    }

    function proposeDriver(uint salary) external {
        require(driverIsProposed == false);
        driver = TaxiDriver({
            salary: salary,
            addressOfDriver: msg.sender,
            approvalStateForDriver: 0,
            fireStateForDriver: 0
        });

        driverIsProposed == true;
    }

    function approveDriver() external {
        require(isApprovedDriverBefore[msg.sender] == false); // Each participant can increment once
        driver.approvalStateForDriver++;
        isApprovedDriverBefore[msg.sender] = true;

        if(numberOfParticipants / 2 < driver.approvalStateForDriver){
            this.setDriver();
        } 
        
    }

    function setDriver() external {

        newDriver = TaxiDriver({
            salary: driver.salary,
            addressOfDriver: driver.addressOfDriver,
            approvalStateForDriver: 0,
            fireStateForDriver: 0
        });

    }

    function proposeFireDriver() external {
        require(isApprovedFireBefore[msg.sender] == false);
        newDriver.fireStateForDriver++;
        if(numberOfParticipants / 2 < newDriver.fireStateForDriver){
            this.fireDriver();
        }
        isApprovedFireBefore[msg.sender] = true;
    }

    function fireDriver( ) external {
        newDriver.addressOfDriver.call{value: balanceOfDriver}("");
        // Setting these variables to default for every field
        newDriver = TaxiDriver(address(0), 0, 0, 0);
        driver = TaxiDriver(address(0), 0, 0, 0);
    }

    function leaveJob() external {
        require(msg.sender == newDriver.addressOfDriver);
        this.fireDriver();
    }

    function getCharge() payable public  {
        contractBalance += msg.value;
    }

    function getSalary() external {
        require(msg.sender == newDriver.addressOfDriver);
        balanceOfDriver += newDriver.salary;
        if(oneMonthPassed){
            newDriver.addressOfDriver.call{value: balanceOfDriver}("");
        }
    }

    function carExpenses() external {
        require(msg.sender == participant.addressOfParticipant);

        if(monthsPassed > 6){
            addressOfCarDealer.call{value: maintenanceAndTaxPrice}("");
        }

    }

    function payDividend() external {
        require(msg.sender == participant.addressOfParticipant && monthsPassed > 6);
        totalProfitForOneParticipant = ( contractBalance + (participationFee * numberOfParticipants) - maintenanceAndTaxPrice - (newDriver.salary * monthsPassed)) / numberOfParticipants; // every six months

        for(uint i = 1; i < temporaryBalanceArray.length; i++){
            temporaryBalanceArray[i] += totalProfitForOneParticipant;
        }
        
    }

    function getDividend() external {
        require(msg.sender == participant.addressOfParticipant);
        participant.addressOfParticipant.call{value: totalProfitForOneParticipant}("");
        temporaryBalanceArray[participantId[msg.sender]] = 0;
    }

    fallback()  external {
        // Fallback Function
    }

}