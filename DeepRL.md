---
title: "**Deep Reinforcement Learning**"
author: Julien Vitay
email: <julien.vitay@informatik.tu-chemnitz.de>
abstract: "The goal of this document is to summarize the state-of-the-art in deep reinforcement learning. It starts with basics in reinforcement learning and deep learning to introduce the notations. It is then composed of three main parts: 1) value-based algorithms (DQN...) 2) policy-gradient based algorithms (A3C, DDPG...) 3) Recurrent attention models (RAM...). Finally it provides and explains code snippets for these algorithms."
autoSectionLabels: True 
secPrefix: Section
figPrefix: Fig.
eqnPrefix: Eq.
linkReferences: true
link-citations: true
autoEqnLabels: true
---

# Introduction

Deep reinforcement learning (deep RL) is the successful interation of deep learning methods, classically used in supervised or unsupervised learning contexts, with reinforcement learning (RL), a well-studied adaptive control method used in problems with delayed and partial feedback [@Sutton1998]. This section starts with the basics of RL, mostly to set the notations, and provides a quick overview of deep neural networks.

## Basic reinforcement learning 

RL methods apply to problems where an agent interacts with an environment in discrete time steps (@fig:agentenv). At time $t$, the agent is in state $s_t$ and decides to perform an action $a_t$. At the next time step, it arrives in the state $s_{t+1}$ and obtains the reward $r_{t+1}$. The goal of the agent is to maximize the reward obtained on the long term.

![Interaction between an agent and its environment [@Sutton1998].](img/rl-agent.jpg){#fig:agentenv width=30%}

### MDP: Markov Decision Process

Most reinforcement learning problems are modeled as **Markov Decision Processes** (MDP) defined by five quantities:

* a state space $\mathcal{S}$ where each state $s$ respects the Markovian property. It can be finite or infinite. 
* an action space $\mathcal{A}$ of actions $a$, which can be finite or infinite, discrete or continuous.
* an initial state distribution $p_0(s_0)$ (from which states is the agent likely to start).
* a transition dynamics model with density $p(s'|s, a)$, sometimes noted $\mathcal{P}_{ss'}^a$. It defines the probability of arriving in the state $s'$ at time $t+1$ when being in the state $s$ and performing the action $a$ a time $t$.
* a reward function $r(s, a, s') : \mathcal{S}\times\mathcal{A}\times\mathcal{S} \rightarrow \Re$ defining the (stochastic) reward obtained after performing $a$ in state $s$ and arriving in $s'$.

The **Markovian property** states that:

$$
    p(s_{t+1}|s_t, a_t) = p(s_{t+1}|s_t, a_t, s_{t-1}, a_{t-1}, \dots s_0, a_0)
$$ 

i.e. you do not need the full history of the agent to predict where it will arrive after an action. If this is not the case, RL methods will not converge (or poorly). For example, solving video games by using a single frame as state is not Markovian: you can not predict in which direction an object is moving based on a single frame. You will either need to stack several consecutive frames together to create Markovian states, or use recurrent networks in the model to integrate non-Markovian states over time and imitate that property (see @sec:recurrent-attention-models).

### POMDP: Partially Observable Markov Decision Process

In many problems (e.g. vision-based), one does not have access to the true states of the agent, but one can only indirectly observe them. For example, in a video game, the true state is defined by a couple of variables: coordinates $(x, y)$ of the two players, position of the ball, speed, etc. However, all you have access to are the raw pixels: sometimes the ball may be hidden behing a wall or a tree, but it still exists in the state space.

In a **Partially Observable Markov Decision Process** (POMDP), observations $o_t$ come from a space $\mathcal{O}$ and are linked to underlying states using the density function $p(o_t| s_t)$. Observations are usually not Markovian, so the full history of observations $h_t = (o_0, a_0, \dots o_t, a_t)$ is needed to solve the problem (see @sec:recurrent-attention-models).

### Policies

The policy defines the behavior of the agent: which action should be taken in each state. One distinguishes two kinds of policies:

* a stochastic policy $\pi : \mathcal{S} \rightarrow P(\mathcal{A})$ defines the probability distribution $P(\mathcal{A})$ of performing an action.
* a deterministic policy $\mu(s_t)$ is a discrete mapping of $\mathcal{S} \rightarrow \mathcal{A}$.

The policy can be used to explore the environment and generate trajectories of states, rewards and actions. The performance of a policy is determined by calculating the **expected discounted return**, i.e. the sum of all rewards received from time step t onwards: 

$$
    R_t = \sum_{k=0}^{\infty} \gamma^k \, r_{t+k+1}
$$

where $0 < \gamma < 1$ is the discount rate and $r_{t+1}$ represents the reward obtained during the transition from $s_t$ to $s_{t+1}$. 

The Q-value of a state-action pair $(s, a)$ is defined as the expected discounted reward received if the agent takes $a$ from a state $s$ and follows the policy distribution $\pi$ thereafter:

$$
    Q^{\pi}(s, a) = {E}_{\pi}(R_t | s_t = s, a_t=a)
$$

Similarly, the V-value of a state $s$ is the expected discounted reward received if the agent starts in $s$ and follows its policy $\pi$. 

$$
    V^{\pi}(s) = {E}_{\pi}(R_t | s_t = s)
$$

Obviously, these quantities depend on the states/actions themselves (some chessboard configurations are intrinsically better than others, i.e. you are more likely to win from that state), but also on the policy (if you can kill your opponent in one move - meaning you are in an intrinsically good state - but systematically take the wrong decision and lose, this is a bad state).

### Bellman equations

The V- and Q-values are obviously linked with each other. The value of state depend on the value of the actions possible in that state, modulated by the probability that an action will be taken (i.e. the policy):

$$
    V^{\pi}(s) = \sum_{a \in \mathcal{A}} \pi(s, a) \, Q^\pi(s,a)
$$ {#eq:v-value}

For a deterministic policy ($\pi(s, a) = 1$ if $a=a^*$ and $0$ otherwise), the value of a state is the same as the value of the action that will be systematically taken.

Noting that:

$$
    R_t = r_{t+1} + \gamma R_{t+1}
$$ {#eq:return}

i.e. that the expected return at time $t$ is the sum of the immediate reward received during the next transition $r_{t+1}$ and of the expected return at the next state ($R_{t+1}$, discounted by $\gamma$), we can also write:

$$
    Q^{\pi}(s, a) = \sum_{s' \in \mathcal{S}} p(s'|s, a) [r(s, a, s') + \gamma \, V^\pi(s')]
$$ {#eq:q-value}

The value of an action depends on which state you arrive in ($s'$), with which probability ($p(s'|s, a)$), how much reward you receive immediately ($r(s, a, s')$) and how much you will receive later (summarized by $V^\pi(s')$).

Putting together @eq:v-value and @eq:q-value, we obtain the **Bellman equations**:

$$
    V^{\pi}(s) = \sum_{a \in \mathcal{A}} \pi(s, a) \, \sum_{s' \in \mathcal{S}} p(s'|s, a) [r(s, a, s') + \gamma \, V^\pi(s')]
$$

$$
    Q^{\pi}(s, a) = \sum_{s' \in \mathcal{S}} p(s'|s, a) [r(s, a, s') + \gamma \, \sum_{a' \in \mathcal{A}} \pi(s', a') \, Q^\pi(s',a')]
$$

The Bellman equations mean that the value of a state (resp. state-action pair) depends on the value of all other states (resp. state-action pairs), the current policy $\pi$ and the dynamics of the MDP ($p(s'|s, a)$ and $r(s, a, s')$).

![Backup diagrams correponding to the Bellman equations [@Sutton1998].](img/backup.png){#fig:backup width=50%}

### Dynamic programming

The interesting property of the Bellman equations is that, if the states have the Markovian property, they admit *one and only one* solution. This means that for a given policy, if the dynamics of the MDP are known, it is possible to compute the value of all states or state-action pairs by solving the Bellman equations for all states or state-action pairs (*policy evaluation*). 

Once the values are known for a given policy, it is possible to improve the policy by selecting with the highest probability the action with the highest Q-value. For example, if the current policy chooses the action $a_1$ over $a_2$ in $s$ ($\pi(s, a_1) > \pi(s, a_2)$), but after evaluating the policy it turns out that $Q^\pi(s, a_2) > Q^\pi(s, a_1)$ (the expected return after $a_2$ is higher than after $a_1$), it makes more sense to preferentially select $a_2$, as there is more reward afterwards. We can then create a new policy $\pi'$ where $\pi'(s, a_2) > \pi'(s, a_1)$, which is is *better* policy than $\pi$ as more reward can be gathered after $s$.

![Dynamic programming alternates between policy evaluation and policy improvement [@Sutton1998].](img/dynamicprogramming.png){#fig:dynamicprogramming width=20%}

**Dynamic programming** (DP) alternates between policy evaluation and policy improvement. If the problem is Markovian, it can be shown that DP converges to the *optimal policy* $\pi^*$, i.e. the policy where the expected return is maximal in all states. 

Note that by definition the optimal policy is *deterministic* and *greedy*: if there is an action with a maximal Q-value for the optimal policy, it should be systematically taken. For the optimal policy $\pi^*$, the Bellman equations become:

$$
    V^{*}(s) = \max_{a \in \mathcal{A}} \sum_{s \in \mathcal{S}} p(s' | s, a) \cdot [ r(s, a, s') + \gamma \cdot V^{*} (s') ]
$$

$$
    Q^{*}(s, a) = \sum_{s' \in \mathcal{S}} p(s' | s, a) \cdot [r(s, a, s') + \gamma \max_{a' \in \mathcal{A}} Q^* (s', a') ]
$$

Dynamic programming can only be used when:

* the dynamics of the MDP ($p(s'|s, a)$ and $r(s, a, s')$) are fully known.
* the number of states and state-action pairs is small (one Bellman equation per state or state/action to solve).

In practice, sample-based methods such as Monte-Carlo or temporal difference are used. 

### Monte-Carlo sampling

![Monte-Carlo methods accumulate rewards over a complete episode. [@Sutton1998].](img/unifiedreturn.png){#fig:mc width=50%}

When the environment is *a priori* unknown, it has to be explored in order to build estimates of the V or Q value functions. The key idea of **Monte-Carlo** sampling (MC) is rather simple:

1. Start from a state $s_0$.
2. Perform an episode (sequence of state-action transitions) until a terminal state $s_T$ is reached using your current policy $\pi$.
3. Accumulate the rewards into the actual return for that episode $R_t^{(e)} = \sum_{k=0}^T r_{t+k+1}$ for each time step.
4. Repeat often enough so that the value of a state $s$ can be approximated by the average of many actual returns: 

$$V^\pi(s) = E^\pi(R_t | s_t = s) = \frac{1}{M} \sum_{e=1}^M R_t^{(e)}$$

In practice, the estimated values are updated using continuous updates:

$$
    V^\pi(s) \leftarrow V^\pi(s) + \alpha (R_t - V^\pi(s))
$$

Q-values can also be approximated using the same procedure:

$$
    Q^\pi(s, a) \leftarrow Q^\pi(s, a) + \alpha (R_t - Q^\pi(s, a))
$$

The two main drawbacks of MC methods are:

1. The task must be episodic, i.e. stop after a finite amount of transitions. Updates are only applied at the end of an episode.
2. A sufficient level of exploration has to be ensured to make sure the estimates converge to the optimal values.

The second issue is linked to the **exploration-exploitation** dilemma: the episode is generated using the current policy (or a policy derived from it, see later). If the policy always select the same actions from the beginning (exploitation), the agent will never discover better alternatives: the values will converge to a local minimum. If the policy always pick randomly actions (exploration), the policy which is evaluated is not the current policy $\pi$, but the random policy. A trade-off between the two therefore has to be maintained: usually a lot of exploration at the beginning of learning to accumulate knowledge about the environment, less towards the end to actually use the knowledge and perform optimally.

There are two types of methods trying to cope with exploration:

* **On-policy** methods generate the episodes using the learned policy $\pi$, but it has to be *$\epsilon$-soft*, i.e. stochastic: it has to let a probability of at least $\epsilon$ of selecting another action than the greedy action (the one with the highest estimated Q-value). 
* **Off-policy** methods use a second policy called the *behavior policy* to generate the episodes, but learn a different policy for exploitation, which can even be deterministic. 

$\epsilon$-soft policies are easy to create. The simplest one is the **$\epsilon$-greedy** action selection method, which assigns a probability $(1-\epsilon)$ of selecting the greedy action (the one with the highest Q-value), and a probability $\epsilon$ of selecting any of the other available actions:

$$ 
    a_t = \begin{cases} a_t^* \quad \text{with probability} \quad (1 - \epsilon) \\
                       \text{any other action with probability } \epsilon \end{cases}
$$

Another solution is the **Softmax** (or Gibbs distribution) action selection method, which assigns to each action a probability of being selected depending on their relative Q-values:

$$
    P(s, a) = \frac{\exp Q^\pi(s, a) / \tau}{ \sum_b \exp Q^\pi(s, b) / \tau}
$$ 

$\tau$ is a positive parameter called the temperature: high temperatures cause the actions to be nearly equiprobable, while low temperatures cause $\tau$ is a positive parameter called the temperature. 

The advantage of off-policy methods is that domain knowledge can be used to restrict the search in the state-action space. For example, only moves actually played by chess experts in a given state will be actually explored, not random stupid moves. The obvious drawback being that if the optimal solution is not explored by the behavior policy, the agent has no way to discover it by itself.

### Temporal Difference

The main drawback of Monte-Carlo methods is that the task must be composed of finite episodes. Not only is it not always possible, but value updates have to wait for the end of the episode, what slows learning down. **Temporal difference** methods simply replace the actual return obtained after a state or an action, by an estimation composed of the reward immediately received plus the value of the next state or action, as in @eq:return:

$$
    R_t \approx r_{t+1} + \gamma \, V^\pi(s_{t+1}) \approx r_{t+1} + \gamma \, Q^\pi(s_{t+1}, a_{t+1})
$$

This gives us the following learning rules:

$$
    V^\pi(s_t) \leftarrow V^\pi(s_t) + \alpha (r_{t+1} + \gamma \, V^\pi(s_{t+1}) - V^\pi(s_t))
$$

$$
    Q^\pi(s_t, a_t) \leftarrow Q^\pi(s_t, a_t) + \alpha (r_{t+1} + \gamma \, Q^\pi(s_{t+1}, a_{t+1}) - Q^\pi(s_t, a_t))
$$

The quantity:

$$
 \delta_t = r_{t+1} + \gamma \, V^\pi(s_{t+1}) - V^\pi(s_t)
$$

or:

$$
    \delta_t = r_{t+1} + \gamma \, Q^\pi(s_{t+1}, a_{t+1}) - Q^\pi(s_t, a_t)
$$

is called the **reward-prediction error** (RPE): it defines the surprise between the current reward prediction ($V^\pi(s_t)$ or $Q^\pi(s_t, a_t)$) and the sum of the immediate reward plus the reward prediction in the next state / after the next action.

* If $\delta_t > 0$, the transition was positively surprising: one obtains more reward or lands in a better state than expected. The initial state or action was actually underrated, so its estimated value must be increased.
* If $\delta_t < 0$, the transition was negatively surprising. The initial state or action was overrated, its value must be decreased.
* If $\delta_t = 0$, the transition was fully predicted: one obtains as much reward as expected, so the values should stay as they are.

The main advantage of this learning method is that the update of the V- or Q-value can be applied immediately after a transition: no need to wait until the end of an episode, or even to have episodes at all. 

![Temporal difference algorithms update values after a single transition. [@Sutton1998].](img/backup-TD.png){#fig:td width=3%}

When learning Q-values directly, the question is which next action $a_{t+1}$ should be used in the update rule: the action that will actually be taken for the next transition (defined by $\pi(s_{t+1}, a_{t+1})$), or the greedy action ($a^* = \text{argmax}_a Q^\pi(s_{t+1}, a)$). This relates to the *on-policy / off-policy* distinction already seen for MC methods:

* *On-policy* TD learning is called **SARSA** (state-action-reward-state-action). It uses the next action sampled from the policy $\pi(s_{t+1}, a_{t+1})$ to update the current transition. It is required that this next action will actually be performed for the next transition. The policy must be $\epsilon$-soft, for example $\epsilon$-greedy or softmax:

$$
    \delta_t = r_{t+1} + \gamma \, Q^\pi(s_{t+1}, a_{t+1}) - Q^\pi(s_t, a_t)
$$

* *Off-policy* TD learning is called **Q-learning** [@Watkins1989]. The greedy action in the next state (the one with the highest Q-value) is used to update the current transition. It does not mean that the greedy action will actually have to be selected for the next transition. The learned policy can therefore also be deterministic:

$$
    \delta_t = r_{t+1} + \gamma \, \max_a Q^\pi(s_{t+1}, a) - Q^\pi(s_t, a_t)
$$

In Q-learning, the behavior policy has to ensure exploration, while this is achieved implicitely by the learned policy in SARSA, as it must be $\epsilon$-soft. An easy way of building a behavior policy based on a deterministic learned policy is $\epsilon$-greedy: the deterministic action $\mu(s_t)$ is chosen with probability 1 - $\epsilon$, the other actions with probability $\epsilon$. In continuous action spaces, additive noise (e.g. Ohrstein-Uhlenbeck) can be added to the action.

Alternatively, domain knowledge can be used to create the behavior policy and restrict the search to meaningful actions: compilation of expert moves in games, approximate solutions, etc. Again, the risk is that the behavior policy never explores the actually optimal actions.

### Actor-critic architectures


Let's consider the reward-prediction error (RPE) based on state values:

$$
 \delta_t = r_{t+1} + \gamma \, V^\pi(s_{t+1}) - V^\pi(s_t)
$$

As noted in the previous section, the RPE represents how surprisingly good (or bad) a transition between two states has been. It can be used to update the value of the state $s_t$:

$$
    V^\pi(s_t) \leftarrow V^\pi(s_t) + \alpha \, \delta_t
$$

This allows to estimate the values of all states for the current policy. However, this does not help to 1) directy select the best action or 2) improve the policy. When only the V-values are given, one can only want to reach the next state $V^\pi(s_{t+1})$ with the highest value: one needs to know which action leads to this better state, i.e. have a model of the environment. Actually, one selects the action with the highest Q-value:

$$
    Q^{\pi}(s, a) = \sum_{s' \in \mathcal{S}} p(s'|s, a) [r(s, a, s') + \gamma \, V^\pi(s')]
$$

An action may lead to a high-valued state, but with such a small probability that it is actually not worth it. $p(s'|s, a)$ and $r(s, a, s')$ therefore have to be known (or at least approximated), what defeats the purpose of sample-based methods.

![Actor-critic architecture.](img/actorcritic.jpg){#fig:actorcritic width=50%}

**Actor-critic** architectures have been proposed to solve this problem:

1. The **critic** learns to estimate the value of a state $V^\pi(s_t)$ and compute the RPE $\delta_t = r_{t+1} + \gamma \, V^\pi(s_{t+1}) - V^\pi(s_t)$.
2. The **actor** uses the RPE to update a *preference* for the executed action: action with positive RPEs (positively surprising) should be reinforced (i.e. taken again in the future), while actions with negative RPEs should be avoided in the future.

The main interest of this architecture is that the actor can take any form (neural network, decision tree), as long as it able to use the RPE for learning.  

### Function approximation 

The goal of the agent is to find the optimal policy maximizing the expected return from every state. \emph{Value-based} methods (such as DQN) achieve that goal by estimating the Q-value of each state-action pair. Discrete algorithms transform these Q-values into a stochastic policy by sampling from a Gibbs distribution (softmax) to obtain the probability of choosing an action. The Q-values can be approximated by a deep neural network, by minimizing the quadratic error between the predicted Q-value $Q^{\pi}(s, a)$ and an estimation of the real expected return $R_t$ after that action:

$$
    \mathcal{L}(\theta) = {E}_{\pi} [r_t + \gamma Q^{\pi}(s_{t+1}, a_{t+1}) - Q^{\pi}(s_t, a_t)]^2
$$



## Deep learning

### Deep neural networks

### Convolutional networks

### Recurrent neural networks

# Value-based methods

## Limitations of deep neural networks for function approximation

## Deep Q Network (DQN)

@Mnih2015

## Double DQN

<https://jaromiru.com/2016/11/07/lets-make-a-dqn-double-learning-and-prioritized-experience-replay/>

@vanHasselt2015

## Prioritised replay

@Schaul2015

## Duelling network

@Wang2016

## GORILA

# Policy-gradient methods

*Policy gradient* methods directly learn to produce the policy (stochastic or not). The goal of the neural network is to maximize an objective function $J(\theta) = {E}_{\pi_\theta}(R_t)$. The \emph{stochastic policy gradient theorem} \cite{Sutton1999} provides a useful estimate of the gradient that should be given to the neural network:

$$
\nabla_\theta J(\theta) = {E}_{\pi_\theta}[\nabla_\theta \log \pi_\theta(s, a) Q^{\pi_\theta}(s, a)]
$$

@Sutton1999, @Silver2014

## REINFORCE

@Williams1992

## A3C

@Mnih2016

HogWild!: @Niu2011

## Continuous action spaces

## Policy gradient theorems

## Stochastic Policy Gradient (SVG)

@Heess2015

## Deterministic Policy Gradient (DPG)

@Silver2014

## Deep Deterministic Policy Gradient (DDPG)

@Lillicrap2015

## Fictitious Self-Play (FSP)

# Recurrent Attention Models

@Mnih2014, @Ba2014. @Stollenga2014

# Deep RL for robotics

@Agrawal2016, @Dosovitskiy2016, @Gu2017, @Levine2016a, @Levine2016b, @Zhang2015

# Code samples

## Environments

* OpenAI Gym <https://gym.openai.com>: a toolkit for comparing RL algorithms.

```python
import gym
env = gym.make("Taxi-v1")
observation = env.reset()
for _ in range(1000):
    env.render()
    action = env.action_space.sample()
    observation, reward, done, info = env.step(action)
```

* OpenAi Universe <https://universe.openai.com>: a framework for controlling video games.

* Darts environment <https://github.com/DartEnv/dart-env>: an extension of gym to use the Darts simulator instead of Mujoco. 

* NIPS 2017 musculoskettal challenge <https://github.com/stanfordnmbl/osim-rl>

## Algorithms

* `rl-code` <https://github.com/rlcode/reinforcement-learning>: many code samples for simple RL problems

    * Gridworld 

        * Policy Iteration
        * Value Iteration
        * Monte Carlo
        * SARSA
        * Q-Learning
        * Deep SARSA
        * REINFORCE

    * CartPole - Applying deep reinforcement learning on basic Cartpole game.   

        * Deep Q Network
        * Double Deep Q Network
        * Policy Gradient
        * Actor Critic (A2C)
        * Asynchronous Advantage Actor Critic (A3C)   

    * Atari - Mastering Atari games with Deep Reinforcement Learning    

        * Breakout - DQN, DDQN Dueling DDQN A3C
        * Pong - Policy Gradient  

    * OpenAI GYM - [WIP]    

        * Mountain Car - DQN

* `keras-rl` <https://github.com/matthiasplappert/keras-rl>: many RL algorithms implemented in keras.

    * Deep Q Learning (DQN)
    * Double DQN
    * Deep Deterministic Policy Gradient (DDPG)
    * Continuous DQN (CDQN or NAF)
    * Cross-Entropy Method (CEM)
    * Dueling network DQN (Dueling DQN)
    * Deep SARSA

* DDPG in tensorflow <http://pemami4911.github.io/blog/2016/08/21/ddpg-rl.html>

# References