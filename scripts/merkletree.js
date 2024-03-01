const { ethers } = require('hardhat');
const { MerkleTree } = require('merkletreejs');
const keccak256 = require('keccak256');

async function main() {
  // List of addresses
  // const addressAmountPairs = [
  //   { address: "0x2F186D06707105CCADE930Adc55eC7D35A189C98", earned1: '1000000000000000000', earned2: '1000000000000000000', earned3: '1000000000000000000', earned4: '1000000000000000000', total: '4000000000000000000' },
  //   { address: "0x9Ef4b0B3087a8b2D9f3a78E6cA81a8bF73DD0097", earned1: '1000000000000000000', earned2: '1000000000000000000', earned3: '1000000000000000000', earned4: '1000000000000000000', total: '4000000000000000000' },
  //   { address: "0x273321eEd515AAD1AE0B6a985875839BBDCaFAE4", earned1: '1000000000000000000', earned2: '1000000000000000000', earned3: '1000000000000000000', earned4: '1000000000000000000', total: '4000000000000000000' },
  //   { address: "0x1Ce32739c33Eecb06dfaaCa0E42bd04E56CCbF0d", earned1: '1000000000000000000', earned2: '1000000000000000000', earned3: '1000000000000000000', earned4: '1000000000000000000', total: '4000000000000000000' }
  // ];
  // get traderReward root for test
  const addressAmountPairs = [{"trader":"0x605dd33bdaf6e8344d79e1059f8cbb36a52a965b","reward":"49373880139087808"},{"trader":"0xb8925deb3391797541c0e3e7883be5b65f648f4d","reward":"57033108987337520"},{"trader":"0xc2e61cfae2a04d4450533d7ce7e0bd9607519aef","reward":"101202169336435184"},{"trader":"0xdd35b9d2b9e2bcfafad29fa17a9ec0010ddd5fe3","reward":"249514592768472000"},{"trader":"0x433617d8e932706a5eed1f3886bbd58c6bb5b545","reward":"513963501830035904"},{"trader":"0x782b941eecbcdcc3a559d9266ce0ec75a37c09bd","reward":"533892075649345536"},{"trader":"0x0b99acf56ea69789073a0dab59094da91a298049","reward":"1026368730401564288"},{"trader":"0x5b8770d29e3426f0787338b6978bc614da43258a","reward":"7828104058214730752"},{"trader":"0xd41c0ec18df28f6be6942addab960eb25b4232a3","reward":"10455149781226633216"},{"trader":"0xb16b77c16773def8fa279a1228eba9308ecd7841","reward":"21907196050614960128"},{"trader":"0xfbc47894163b9d10c8a5279ee07b1397ea1cb877","reward":"24666979641342398464"},{"trader":"0xe7f63ed096e58c3fcdad3732af49fa1436cb9077","reward":"29555671197658796032"},{"trader":"0x0806a0cd0bc0e9a827513a8777d5ac901e2f021d","reward":"33210411951350689792"},{"trader":"0x0a00c3474a73bc001857c93b90650e0e04ab2ab7","reward":"33735804245177061376"},{"trader":"0x2f186d06707105ccade930adc55ec7d35a189c98","reward":"39405437502072889344"},{"trader":"0xf1618dedcd73865102bd99a432b52801e1221d60","reward":"61974847897775349760"},{"trader":"0xec02b7d4256cc7edfe98029cad336fdfeabfe931","reward":"89255674421738930176"},{"trader":"0x1ce32739c33eecb06dfaaca0e42bd04e56ccbf0d","reward":"136268375871625412608"},{"trader":"0xfb5f7fd53891802cf308e15a83bbcd8de154aea4","reward":"187531370753488158720"},{"trader":"0x17c1b4f4f28c84f4c2cca2ed672cd8ce9e590407","reward":"496003171475542638592"},{"trader":"0xc313809ca2084f83453eb183084a276a5b7c5c74","reward":"805297283558577537024"},{"trader":"0x771fa8d8dfc0656c83371859a0e08d8368c97907","reward":"24520373173534477778944"}]
  // Hashing the addresses
  const leaves = addressAmountPairs.map(pair => keccak256(ethers.utils.solidityPack(["address", "uint256"], [pair.trader, pair.reward])));

  //const leaves = addressAmountPairs.map(pair => keccak256(ethers.utils.solidityPack(["address", "uint256"], [pair.address, pair.total])));

  // Creating the Merkle tree
  const tree = new MerkleTree(leaves, keccak256, { sortPairs: true });

  // Getting the Merkle root
  const root = tree.getRoot().toString('hex');

  console.log("Merkle Root:", root);
  const myAddress = "0xC2e61CFae2A04d4450533d7Ce7E0BD9607519aEf"; // replace with your address
  const myAmount = "101202169336435184"; // replace with your amount
  const leaf = keccak256(ethers.utils.solidityPack(["address", "uint256"], [myAddress, myAmount]));
  const proof = tree.getHexProof(leaf);
  console.log("Merkle Proof for my address:", proof);
}
// Merkle Root: 9e63bf2109f8fdd19f413b2cbf3aca1fb4d89fc02f45a9266767efa38608a3c5
// Merkle Proof for my address: [
//   '0x74e64fdc2709195357e03f166955a1aa5053806c13bcf94a4d744531b8fcb8ac',
//   '0xaba1f3ac4d138109a1a4636df70782e1070eeafcc5cbaa78420b4fb88a83cb01'
// ]
main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
