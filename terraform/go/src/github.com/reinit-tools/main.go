package main

import (
  "fmt"
  "os"
  "sort"
  "bytes"
  "math/big"
  "encoding/json"
  "crypto/ecdsa"

  "github.com/ethereum/go-ethereum/common"
  "github.com/ethereum/go-ethereum/core"
  "github.com/ethereum/go-ethereum/core/types"
  "github.com/ethereum/go-ethereum/crypto"
  "github.com/ethereum/go-ethereum/params"
  "github.com/ethereum/go-ethereum/rlp"
)

func main() {
  var nodekeys []string;
  // Get list of nodekeys from input
  for i := 1 ; i < len(os.Args); i ++ {
    nodekeys = append(nodekeys, os.Args[i]);
  }

  var stringAddrs []string;
  _, _, addr := GenerateKeysWithNodeKey(nodekeys);
  // Convert to String to sort
  for i := 0; i < len(addr); i++ {
    addrString, _ := json.Marshal(addr[i]);
    stringAddrs = append(stringAddrs, string(addrString));
  }
  sort.Strings(stringAddrs);

  // Convert back to address
  var addrs []common.Address;
  for i := 0; i < len(stringAddrs); i++ {
    var address common.Address;
    json.Unmarshal([]byte(stringAddrs[i]), &address);
    addrs = append(addrs, address);
  }
  // Generate Genesis block
  genesis := GetGenesisWithAddrs(addrs);
  genesisS, _ := json.Marshal(genesis);
  fmt.Println(string(genesisS));
}

func GenerateKeysWithNodeKey(nodekeysIn []string) (keys []*ecdsa.PrivateKey, nodekeys []string, addrs []common.Address) {
  for i := 0; i < len(nodekeysIn); i++ {
    nodekey := nodekeysIn[i]
    nodekeys = append(nodekeys, nodekey)

    key, err := crypto.HexToECDSA(nodekey)
    if err != nil {
      fmt.Println("Failed to generate key", "err", err)
      return nil, nil, nil
    }
    keys = append(keys, key)

    addr := crypto.PubkeyToAddress(key.PublicKey)
    addrs = append(addrs, addr)
  }
  return keys, nodekeys, addrs
}

var (
  defaultDifficulty = big.NewInt(1)
  emptyNonce        = types.BlockNonce{}
)

func GetGenesisWithAddrs(addrs []common.Address) (*core.Genesis) {
  // generate genesis block
  genesis := core.DefaultGenesisBlock()
  for k := range genesis.Alloc {
    delete(genesis.Alloc, k)
}
  genesis.Config = params.TestChainConfig
  // force enable Istanbul engine

  defaultIstanbulConfig := &params.IstanbulConfig{}
  defaultIstanbulConfig.Epoch = 30000
  genesis.Config.Istanbul = defaultIstanbulConfig

  genesis.Config.Ethash = nil
  genesis.Difficulty = defaultDifficulty
  genesis.Nonce = emptyNonce.Uint64()
  genesis.Mixhash = types.IstanbulDigest
  genesis.GasLimit = 4700000;

  appendValidators(genesis, addrs)
  return genesis
}

func appendValidators(genesis *core.Genesis, addrs []common.Address) {

  if len(genesis.ExtraData) < types.IstanbulExtraVanity {
    genesis.ExtraData = append(genesis.ExtraData, bytes.Repeat([]byte{0x00}, types.IstanbulExtraVanity)...)
  }
  genesis.ExtraData = genesis.ExtraData[:types.IstanbulExtraVanity]

  ist := &types.IstanbulExtra{
    Validators:    addrs,
    Seal:          []byte{},
    CommittedSeal: [][]byte{},
  }

  istPayload, err := rlp.EncodeToBytes(&ist)
  if err != nil {
    panic("failed to encode istanbul extra")
  }
  genesis.ExtraData = append(genesis.ExtraData, istPayload...)
}

// 7node nodekey example
// go run main.go 1be3b50b31734be48452c29d714941ba165ef0cbf3ccea8ca16c45e3d8d45fb0 9bdd6a2e7cc1ca4a4019029df3834d2633ea6e14034d6dcc3b944396fe13a08b 722f11686b2277dcbd72713d8a3c81c666b585c337d47f503c3c1f3c17cf001d 6af685c4de99d44c620ccd9464d19bdeb62a750b9ae49b1740fb28d68a0e5c7d 103bb5d20384b9af9f693d4287822fef6da7d79cb2317ed815f0081c7ea8d17d 79999aef8d5197446b6051df47f01fd4d6dd1997aec3f5282e77ea27b6727346 e85dae073b504871ffd7946bf5f45e6fa8dc09eb1536a48c4b6822332008973d
