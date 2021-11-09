// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/**
 * @title Permissioned pool actions
 * @notice Contains pool methods that may only be called by the factory owner or farming
 */
interface IAlgebraPoolPermissionedActions {
    /**
     * @notice Set the community's % share of the fees
     * @param communityFee0 new community fee percent for token0 of the pool
     * @param communityFee1 new community fee percent for token1 of the pool
     */
    function setCommunityFee(uint8 communityFee0, uint8 communityFee1) external;

    /**
     * @notice Sets an active incentive
     * @param virtualPoolAddress The address of a virtual pool associated with the incentive
     * @param endTimestamp The timestamp when the active incentive is finished
     * @param startTimestamp The first swap after this timestamp is going to initialize the virtual pool
     */
    function setIncentive(
        address virtualPoolAddress,
        uint32 endTimestamp,
        uint32 startTimestamp
    ) external;
}
