<template>
    <div>
        <div id="top-menu-logo">
            <b-modal id="standings-table" hide-footer title="Standings">
                <b-container fluid class="p-0">
                    <b-row>
                        <b-col class="font-weight-bold" cols="3">Place</b-col>
                        <b-col class="font-weight-bold" cols="3">Wallet</b-col>
                        <b-col class="font-weight-bold" cols="3">Captured</b-col>
                        <b-col class="font-weight-bold" cols="3">Reward</b-col>
                    </b-row>

                    <b-row v-for="(player, index) in $store.state.Game.standings" :key="player.playerAddress"
                           :class="{active: isCurrentPlayer(player.playerAddress)}">
                        <b-col class="text-center">{{ index + 1 }}
                        </b-col>
                        <b-col class="text-left">{{ player.playerAddress | short }}</b-col>
                        <b-col class="text-center p-0">{{ player.captured }}
                            <i class="bi bi-star-fill gold-star small" v-show="player.isLast"></i>
                            <i class="bi bi-star gold-star small" v-show="player.isPrelast"></i>
                        </b-col>
                        <b-col>{{ player.reward | fixed }}</b-col>
                    </b-row>
                    <b-row>
                        <b-col class="mt-2">
                            <p class="small" v-if="gameActive"><b>Note: </b>Until the game is completed, rewards for the last (10%) and pre-last (5%) tiles are
                                excluded from the calculation.</p>
                            <p class="small" v-if="!gameActive">
                               <i class="bi bi-star-fill gold-star"></i> = Player claimed the last tile<br/>
                               <i class="bi bi-star gold-star"></i> = Player claimed the pre-last tile
                            </p>
                        </b-col>
                    </b-row>
                </b-container>
            </b-modal>

            <b-modal id="sale-token" hide-footer title="Get PILE Tokens!">
                <p>To get PILE tokens, simply send EVERs to the following address (minimum: 1 EVER).<br/></p>
                <b-input-group>
                    <b-form-input :value="saleTokenAddress"
                               v-on:focus="$event.target.select()"
                               ref="tsAddress"
                               readonly>
                    </b-form-input>
                    <template #append>
                        <b-button variant="primary" v-on:click="copyAddress">Copy</b-button>
                    </template>
                </b-input-group>
                <p class="mt-3">Your connected wallet is: <b>{{ $store.state.PlayerInfo.playerAddress | short }}</b><br/>Send money only from this wallet!</p>
                <p class="mt-1">You will receive <b>X5</b> PILE tokens. For example, if you send 10 EVER, you will receive 50 PILE. The exchange is automatic.</p>
                <p><b>Farming Calculator</b></p>
                <p>Use this calculator to approximate how many PILE to buy to have the expected amount of tiles farmed.</p>
                <b-input-group prepend="After this time (in min):" size="sm">
                    <b-form-input v-model="farmingTime" placeholder="Time in minutes" ></b-form-input>
                </b-input-group>
                <b-input-group size="sm" prepend="If your balance is (PILE):">
                    <b-form-input v-model="farmingBalance" placeholder="Your balance" size="sm"></b-form-input>
                    <b-input-group-append>
                        <b-button v-on:click="calcFarming">Calculate</b-button>
                    </b-input-group-append>
                </b-input-group>

                <p>You'll farm: <b>{{ farmingResult }}</b> tiles</p>
            </b-modal>

            <img src="~@/assets/logo.svg" alt="PileBlocks" class="logo-img"/>
        </div>
        <div id="top-menu-player-info">
            <p class="mb-0"><span class="text-faded">Balance: </span>
                <fancy-number :value='this.$store.getters["PlayerInfo/getBalance"]'/>
                <i class="bi bi-cart-check-fill color-primary pl-1" v-on:click="$bvModal.show('sale-token')"></i>
            </p>
            <div class="reward-grid">
                <div class="reward-label"><span class="text-faded pr-1">Your Reward: </span></div>
                <div class="reward-value">
                    <div class="d-inline-block position-absolute">
                        <fancy-number :value='this.$store.getters["Game/getReward"]'/>
                        (<span
                        :class="rewardProcentClass()">{{ rewardProcent }}%</span>)
                        <div :class="setAnimationClass">{{ animatedReward }}</div>
                    </div>
                </div>
            </div>
        </div>
        <div id="top-menu-game-stats">
            <b-button size="sm" variant="primary" v-on:click="$bvModal.show('standings-table')"><i
                class="bi bi-person-lines-fill"></i>
                {{ $store.state.Game.standings.length }}
            </b-button>
        </div>
        <div id="top-menu-game-reload">
            <b-button size="sm" variant="primary" :disabled="isOpInProgress" v-on:click="reloadGame">
                <i class="bi bi-arrow-clockwise" v-show="!isLoading"></i>
                <b-spinner v-show="isLoading" small></b-spinner>
            </b-button>
        </div>
    </div>
</template>

<script lang="js">
// @flow
import BigNumber from "bignumber.js";
import FancyNumber from "./FancyNumber";
import {SALE_TOKEN} from "@/AppConst";
import {GAME_STATUS_COMPLETED} from "@/AppConst";

export default {
    name: "TopMenu",
    components: {FancyNumber},
    data: function () {
        return {
            animatedReward: "",
            setAnimationClass: "reward-base ",
            isLoading: false,
            saleTokenAddress: SALE_TOKEN,
            farmingTime: 0,
            farmingBalance: 0,
            farmingResult: 0
        }
    },
    methods: {
        animateReward: function (isRaising: boolean) {

            this.animatedReward = new BigNumber(this.$store.getters["Game/getReward"]).toFixed(2);
            this.setAnimationClass += "reward-animation ";
            if (isRaising) {
                this.setAnimationClass += "reward-raise ";
            } else {
                this.setAnimationClass += "reward-decline ";
            }

            setTimeout(() => {
                this.setAnimationClass = "reward-base ";
                this.animatedReward = "";
            }, 900)
        },
        isCurrentPlayer: function (playerAddress: string): boolean {
            return playerAddress === this.$store.state.PlayerInfo.playerAddress
        },
        rewardProcentClass: function () {
            const rewardProcent: number = parseFloat(this.rewardProcent);
            switch (true) {
                case (rewardProcent < 5):
                    return "low-procent"
                case (rewardProcent < 10):
                    return "medium-procent"
            }
            return "high-procent"
        },
        reloadGame: async function () {
            this.isLoading = true;
            await this.$store.dispatch('Ever/reloadGame');
            this.isLoading = false;
        },

        copyAddress: function() {
            this.$refs.tsAddress.focus();
            document.execCommand('copy');
        },
        calcFarming: async function() {
            this.farmingResult = await this.$store.getters["Ever/calcFarming"](this.farmingTime * 60, this.farmingBalance * 1e9);
        }

    },
    watch: {
        rewardChange: function (newReward, oldReward) {
            if (oldReward !== 0) {
                this.animateReward(newReward > oldReward);
            }

        }
    },
    computed: {
        rewardChange: function () {
            return this.$store.getters["Game/getReward"];
        },
        rewardProcent: function () {
            if (this.$store.state.Game.status !== GAME_STATUS_COMPLETED) {
                return new BigNumber(this.$store.getters["Game/getReward"] * 100 / this.$store.state.Game.totalRewardDynamic).toFixed(1);
            } else {
                return new BigNumber(this.$store.getters["Game/getReward"] * 100 / this.$store.state.Game.totalReward).toFixed(1);
            }
        },
        gameActive: function () {
            return this.$store.state.Game.status !== GAME_STATUS_COMPLETED;
        },
        isOpInProgress: function(): boolean {
            return this.$store.state.Ever.operationInProgress;
        }
    },
    mounted() {
        this.$store.commit('Game/calculateRewards');
    }
}
</script>

<style scoped>
.text-faded {
    color: #aab0bc;
}



@keyframes text-enlarge {
    0% {
        font-size: 16px;
        opacity: 1;
        left: 0;
        top: 0;
    }
    100% {
        font-size: 48px;
        opacity: 0;
        top: -30px;
        left: -10px;
    }
}

.reward-animation {
    animation-name: text-enlarge;
    animation-duration: 1s;
}

.reward-base {
    position: absolute;
    display: inline-block;
    top: 0;
    left: 0;
}

.reward-raise {
    color: var(--green);
}

.reward-decline {
    color: var(--danger);
}

.active {
    background-color: var(--primary);
}

.high-procent {
    color: var(--green);
}

.low-procent {
    color: var(--danger);
}

.medium-procent {
    color: var(--orange);
}
.gold-star {
    color: var(--gray-dark)
}
.reward-grid {
    display: grid;
    grid-template-rows: 1fr;
    grid-template-columns: 5em 1fr;
}

.reward-label {
    grid-column: 1;
    grid-row: 1;
}

.reward-value {
    grid-column: 2;
    grid-row: 1;
}

</style>
