/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */
import {
  BaseContract,
  BigNumber,
  BigNumberish,
  BytesLike,
  CallOverrides,
  ContractTransaction,
  Overrides,
  PopulatedTransaction,
  Signer,
  utils,
} from "ethers";
import { FunctionFragment, Result } from "@ethersproject/abi";
import { Listener, Provider } from "@ethersproject/providers";
import { TypedEventFilter, TypedEvent, TypedListener, OnEvent } from "./common";

export interface INurseryInterface extends utils.Interface {
  functions: {
    "allocateSeigniorage(uint256)": FunctionFragment;
    "balanceOf(address)": FunctionFragment;
    "canClaimReward(address)": FunctionFragment;
    "canWithdraw(address)": FunctionFragment;
    "claimReward()": FunctionFragment;
    "earned(address)": FunctionFragment;
    "epoch()": FunctionFragment;
    "exit()": FunctionFragment;
    "getKittyPrice()": FunctionFragment;
    "governanceRecoverUnsupported(address,uint256,address)": FunctionFragment;
    "nextEpochPoint()": FunctionFragment;
    "setLockUp(uint256,uint256)": FunctionFragment;
    "setOperator(address)": FunctionFragment;
    "stake(uint256)": FunctionFragment;
    "withdraw(uint256)": FunctionFragment;
  };

  encodeFunctionData(
    functionFragment: "allocateSeigniorage",
    values: [BigNumberish]
  ): string;
  encodeFunctionData(functionFragment: "balanceOf", values: [string]): string;
  encodeFunctionData(
    functionFragment: "canClaimReward",
    values: [string]
  ): string;
  encodeFunctionData(functionFragment: "canWithdraw", values: [string]): string;
  encodeFunctionData(
    functionFragment: "claimReward",
    values?: undefined
  ): string;
  encodeFunctionData(functionFragment: "earned", values: [string]): string;
  encodeFunctionData(functionFragment: "epoch", values?: undefined): string;
  encodeFunctionData(functionFragment: "exit", values?: undefined): string;
  encodeFunctionData(
    functionFragment: "getKittyPrice",
    values?: undefined
  ): string;
  encodeFunctionData(
    functionFragment: "governanceRecoverUnsupported",
    values: [string, BigNumberish, string]
  ): string;
  encodeFunctionData(
    functionFragment: "nextEpochPoint",
    values?: undefined
  ): string;
  encodeFunctionData(
    functionFragment: "setLockUp",
    values: [BigNumberish, BigNumberish]
  ): string;
  encodeFunctionData(functionFragment: "setOperator", values: [string]): string;
  encodeFunctionData(functionFragment: "stake", values: [BigNumberish]): string;
  encodeFunctionData(
    functionFragment: "withdraw",
    values: [BigNumberish]
  ): string;

  decodeFunctionResult(
    functionFragment: "allocateSeigniorage",
    data: BytesLike
  ): Result;
  decodeFunctionResult(functionFragment: "balanceOf", data: BytesLike): Result;
  decodeFunctionResult(
    functionFragment: "canClaimReward",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "canWithdraw",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "claimReward",
    data: BytesLike
  ): Result;
  decodeFunctionResult(functionFragment: "earned", data: BytesLike): Result;
  decodeFunctionResult(functionFragment: "epoch", data: BytesLike): Result;
  decodeFunctionResult(functionFragment: "exit", data: BytesLike): Result;
  decodeFunctionResult(
    functionFragment: "getKittyPrice",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "governanceRecoverUnsupported",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "nextEpochPoint",
    data: BytesLike
  ): Result;
  decodeFunctionResult(functionFragment: "setLockUp", data: BytesLike): Result;
  decodeFunctionResult(
    functionFragment: "setOperator",
    data: BytesLike
  ): Result;
  decodeFunctionResult(functionFragment: "stake", data: BytesLike): Result;
  decodeFunctionResult(functionFragment: "withdraw", data: BytesLike): Result;

  events: {};
}

export interface INursery extends BaseContract {
  connect(signerOrProvider: Signer | Provider | string): this;
  attach(addressOrName: string): this;
  deployed(): Promise<this>;

  interface: INurseryInterface;

  queryFilter<TEvent extends TypedEvent>(
    event: TypedEventFilter<TEvent>,
    fromBlockOrBlockhash?: string | number | undefined,
    toBlock?: string | number | undefined
  ): Promise<Array<TEvent>>;

  listeners<TEvent extends TypedEvent>(
    eventFilter?: TypedEventFilter<TEvent>
  ): Array<TypedListener<TEvent>>;
  listeners(eventName?: string): Array<Listener>;
  removeAllListeners<TEvent extends TypedEvent>(
    eventFilter: TypedEventFilter<TEvent>
  ): this;
  removeAllListeners(eventName?: string): this;
  off: OnEvent<this>;
  on: OnEvent<this>;
  once: OnEvent<this>;
  removeListener: OnEvent<this>;

  functions: {
    allocateSeigniorage(
      _amount: BigNumberish,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<ContractTransaction>;

    balanceOf(_member: string, overrides?: CallOverrides): Promise<[BigNumber]>;

    canClaimReward(
      _member: string,
      overrides?: CallOverrides
    ): Promise<[boolean]>;

    canWithdraw(_member: string, overrides?: CallOverrides): Promise<[boolean]>;

    claimReward(
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<ContractTransaction>;

    earned(_member: string, overrides?: CallOverrides): Promise<[BigNumber]>;

    epoch(overrides?: CallOverrides): Promise<[BigNumber]>;

    exit(
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<ContractTransaction>;

    getKittyPrice(overrides?: CallOverrides): Promise<[BigNumber]>;

    governanceRecoverUnsupported(
      _token: string,
      _amount: BigNumberish,
      _to: string,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<ContractTransaction>;

    nextEpochPoint(overrides?: CallOverrides): Promise<[BigNumber]>;

    setLockUp(
      _withdrawLockupEpochs: BigNumberish,
      _rewardLockupEpochs: BigNumberish,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<ContractTransaction>;

    setOperator(
      _operator: string,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<ContractTransaction>;

    stake(
      _amount: BigNumberish,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<ContractTransaction>;

    withdraw(
      _amount: BigNumberish,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<ContractTransaction>;
  };

  allocateSeigniorage(
    _amount: BigNumberish,
    overrides?: Overrides & { from?: string | Promise<string> }
  ): Promise<ContractTransaction>;

  balanceOf(_member: string, overrides?: CallOverrides): Promise<BigNumber>;

  canClaimReward(_member: string, overrides?: CallOverrides): Promise<boolean>;

  canWithdraw(_member: string, overrides?: CallOverrides): Promise<boolean>;

  claimReward(
    overrides?: Overrides & { from?: string | Promise<string> }
  ): Promise<ContractTransaction>;

  earned(_member: string, overrides?: CallOverrides): Promise<BigNumber>;

  epoch(overrides?: CallOverrides): Promise<BigNumber>;

  exit(
    overrides?: Overrides & { from?: string | Promise<string> }
  ): Promise<ContractTransaction>;

  getKittyPrice(overrides?: CallOverrides): Promise<BigNumber>;

  governanceRecoverUnsupported(
    _token: string,
    _amount: BigNumberish,
    _to: string,
    overrides?: Overrides & { from?: string | Promise<string> }
  ): Promise<ContractTransaction>;

  nextEpochPoint(overrides?: CallOverrides): Promise<BigNumber>;

  setLockUp(
    _withdrawLockupEpochs: BigNumberish,
    _rewardLockupEpochs: BigNumberish,
    overrides?: Overrides & { from?: string | Promise<string> }
  ): Promise<ContractTransaction>;

  setOperator(
    _operator: string,
    overrides?: Overrides & { from?: string | Promise<string> }
  ): Promise<ContractTransaction>;

  stake(
    _amount: BigNumberish,
    overrides?: Overrides & { from?: string | Promise<string> }
  ): Promise<ContractTransaction>;

  withdraw(
    _amount: BigNumberish,
    overrides?: Overrides & { from?: string | Promise<string> }
  ): Promise<ContractTransaction>;

  callStatic: {
    allocateSeigniorage(
      _amount: BigNumberish,
      overrides?: CallOverrides
    ): Promise<void>;

    balanceOf(_member: string, overrides?: CallOverrides): Promise<BigNumber>;

    canClaimReward(
      _member: string,
      overrides?: CallOverrides
    ): Promise<boolean>;

    canWithdraw(_member: string, overrides?: CallOverrides): Promise<boolean>;

    claimReward(overrides?: CallOverrides): Promise<void>;

    earned(_member: string, overrides?: CallOverrides): Promise<BigNumber>;

    epoch(overrides?: CallOverrides): Promise<BigNumber>;

    exit(overrides?: CallOverrides): Promise<void>;

    getKittyPrice(overrides?: CallOverrides): Promise<BigNumber>;

    governanceRecoverUnsupported(
      _token: string,
      _amount: BigNumberish,
      _to: string,
      overrides?: CallOverrides
    ): Promise<void>;

    nextEpochPoint(overrides?: CallOverrides): Promise<BigNumber>;

    setLockUp(
      _withdrawLockupEpochs: BigNumberish,
      _rewardLockupEpochs: BigNumberish,
      overrides?: CallOverrides
    ): Promise<void>;

    setOperator(_operator: string, overrides?: CallOverrides): Promise<void>;

    stake(_amount: BigNumberish, overrides?: CallOverrides): Promise<void>;

    withdraw(_amount: BigNumberish, overrides?: CallOverrides): Promise<void>;
  };

  filters: {};

  estimateGas: {
    allocateSeigniorage(
      _amount: BigNumberish,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<BigNumber>;

    balanceOf(_member: string, overrides?: CallOverrides): Promise<BigNumber>;

    canClaimReward(
      _member: string,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    canWithdraw(_member: string, overrides?: CallOverrides): Promise<BigNumber>;

    claimReward(
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<BigNumber>;

    earned(_member: string, overrides?: CallOverrides): Promise<BigNumber>;

    epoch(overrides?: CallOverrides): Promise<BigNumber>;

    exit(
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<BigNumber>;

    getKittyPrice(overrides?: CallOverrides): Promise<BigNumber>;

    governanceRecoverUnsupported(
      _token: string,
      _amount: BigNumberish,
      _to: string,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<BigNumber>;

    nextEpochPoint(overrides?: CallOverrides): Promise<BigNumber>;

    setLockUp(
      _withdrawLockupEpochs: BigNumberish,
      _rewardLockupEpochs: BigNumberish,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<BigNumber>;

    setOperator(
      _operator: string,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<BigNumber>;

    stake(
      _amount: BigNumberish,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<BigNumber>;

    withdraw(
      _amount: BigNumberish,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<BigNumber>;
  };

  populateTransaction: {
    allocateSeigniorage(
      _amount: BigNumberish,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<PopulatedTransaction>;

    balanceOf(
      _member: string,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    canClaimReward(
      _member: string,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    canWithdraw(
      _member: string,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    claimReward(
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<PopulatedTransaction>;

    earned(
      _member: string,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    epoch(overrides?: CallOverrides): Promise<PopulatedTransaction>;

    exit(
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<PopulatedTransaction>;

    getKittyPrice(overrides?: CallOverrides): Promise<PopulatedTransaction>;

    governanceRecoverUnsupported(
      _token: string,
      _amount: BigNumberish,
      _to: string,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<PopulatedTransaction>;

    nextEpochPoint(overrides?: CallOverrides): Promise<PopulatedTransaction>;

    setLockUp(
      _withdrawLockupEpochs: BigNumberish,
      _rewardLockupEpochs: BigNumberish,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<PopulatedTransaction>;

    setOperator(
      _operator: string,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<PopulatedTransaction>;

    stake(
      _amount: BigNumberish,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<PopulatedTransaction>;

    withdraw(
      _amount: BigNumberish,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<PopulatedTransaction>;
  };
}
