const { expect } = require("chai");
const { ethers } = require("hardhat");


describe("Platform", function () {
  it("Create Platform Contract", async function() {
    const Platform = await ethers.getContractFactory("Platform");
    const ERCToken = await ethers.getContractFactory("ERC20");

    const [owner1, platform_owner] = await ethers.getSigners();
    const [owner2, token_owner] = await ethers.getSigners();

    const platformToken = await ERCToken.connect(platform_owner).deploy("P", "PFT", platform_owner.address);
    const saleToken = await ERCToken.connect(token_owner).deploy("TESTToken", "TST", token_owner.address);
    const platform = await Platform.deploy(platform_owner.address, platformToken.address);

    expect(await platform.registerSaleToken(saleToken.address, "test", 1, 1000, 10));
    expect(await platform.getSaleTokenInfo(saleToken.address)).to.equal(0);

    expect(await saleToken.connect(token_owner).balanceOf(token_owner.address)).to.equal(10000000000000);
    saleToken.connect(token_owner).approve(platform.address, 1000);
    expect(await saleToken.connect(token_owner).allowance(token_owner.address, platform.address)).to.equal(1000);
    platform.connect(token_owner).depositSaleToken(saleToken.address, 1000);
    expect(await saleToken.connect(token_owner).balanceOf(platform.address)).to.equal(1000);
    expect(await platform.checkTheBalance(saleToken.address)).to.equal(1000);
    expect(await platform.getSaleTokenInfo(saleToken.address)).to.equal(1000);
  });
});


describe("Deposit", function () {
  it("Deposit tokens", async function() {
    const Platform = await ethers.getContractFactory("Platform");
    const ERCToken = await ethers.getContractFactory("ERC20");

    const [owner1, platform_owner] = await ethers.getSigners();

    const platformToken = await ERCToken.connect(platform_owner).deploy("P", "PFT", platform_owner.address);
    const platform = await Platform.deploy(platform_owner.address, platformToken.address);

    await platformToken.connect(platform_owner).approve(platform.address, 2000);
    await platform.connect(platform_owner).deposit(1000);
    const ret = await platform.getDepositedBlockNumbers(platform_owner.address);
    const return_number = ret[0].toNumber();
    expect(await platform.getDepositAmountByBlockNumber(platform_owner.address, return_number)).to.equal(1000);

    await platform.connect(platform_owner).deposit(1000);
    const ret2 = await platform.getDepositedBlockNumbers(platform_owner.address);
    const return_number2 = ret2[1].toNumber();
    expect(await platform.getDepositAmountByBlockNumber(platform_owner.address, return_number2)).to.equal(2000);
  });
});

describe("Full Funding", function () {
  it("Deposit tokens", async function() {
    const Platform = await ethers.getContractFactory("Platform");
    const ERCToken = await ethers.getContractFactory("ERC20");

    const [owner1, platform_owner] = await ethers.getSigners();
    const [owner2, token_owner] = await ethers.getSigners();

    // ========== 세일 토큰 등록 ========= //
    const platformToken = await ERCToken.connect(platform_owner).deploy("P", "PFT", platform_owner.address);
    const saleToken = await ERCToken.connect(token_owner).deploy("TESTToken", "TST", token_owner.address);
    const platform = await Platform.deploy(platform_owner.address, platformToken.address);

    expect(await platform.registerSaleToken(saleToken.address, "test", 1, 10000, 10));
    expect(await platform.getSaleTokenInfo(saleToken.address)).to.equal(0);

    saleToken.connect(token_owner).approve(platform.address, 10000);
    platform.connect(token_owner).depositSaleToken(saleToken.address, 10000);

    // ========== user deposit ========= //
    await platformToken.connect(platform_owner).approve(platform.address, 2000);
    await platform.connect(platform_owner).deposit(2000);
    const ret = await platform.getDepositedBlockNumbers(platform_owner.address);
    const return_number = ret[0].toNumber();
    console.log(return_number);
    expect(await platform.getDepositAmountByBlockNumber(platform_owner.address, return_number)).to.equal(2000);


    // =========== token swap ========= //
    const ret_tx = await platform.connect(platform_owner).participateTokenSale(saleToken.address, 1000);
    console.log(ret_tx);
    expect(await saleToken.balanceOf(platform_owner.address)).to.equal(9999999991000);
    expect(await platform.getSaleTokenInfo(saleToken.address)).to.equal(9000);
    expect(await platform.getSwappedAmount(saleToken.address, platform_owner.address)).to.equal(1000);
  });
});
