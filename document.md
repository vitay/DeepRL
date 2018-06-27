---
# Metadata
title: Deep Reinforcement Learning
author: Julien Vitay
email: julien.vitay@informatik.tu-chemnitz.de

# List of files to include
files:
    - 0-Introduction.md
    - 1.1-BasicRL.md
    - 1.2-DeepLearning.md
    - 2-Valuebased.md
    - 3.1-PolicyGradient.md
    - 3.2-ActorCritic.md
    - 3.3-DPG.md
    - 3.4-NaturalGradient.md
    # - 4-RAM.md
    # - 5-ModelBased.md
    # - 6-Robotics.md
    - 7-Practice.md
    - 8-References.md

# Bibliography
bibliography: 
    - /home/vitay/Articles/biblio/ReinforcementLearning.bib
    - /home/vitay/Articles/biblio/DeepLearning.bib
csl: assets/apalike.csl


# CSS
css: assets/github.css
mathjax: /usr/share/mathjax/MathJax.js?config=TeX-AMS-MML_HTMLorMML
# mathjax: https://cdnjs.cloudflare.com/ajax/libs/mathjax/2.7.1/MathJax.js?config=TeX-AMS-MML_HTMLorMML

# Latex
geometry: "margin=1in" 
fontfamily: "times" 
fontsize: "11pt"
header-includes:
    - \usepackage{setspace}
    - \onehalfspacing

---

# Introduction

The goal of this document is to keep track the state-of-the-art in deep reinforcement learning. It starts with basics in reinforcement learning and deep learning to introduce the notations and covers different classes of deep RL methods, value-based or policy-based, model-free or model-based, etc.

Different classes of deep RL methods can be identified. This document will focus on the following ones:   

1. Value-based algorithms (DQN...) used mostly for discrete problems like video games.
2. Policy-gradient algorithms (A3C, DDPG...) used for continuous control problems such as robotics.
3. Recurrent attention models (RAM...) for partially observable problems.
4. Model-based RL to reduce the sample complexity by incorporating a model of the environment.
5. Application of deep RL to robotics

One could extend the list and talk about hierarchical RL, inverse RL, imitation-based RL, etc...

**Additional resources**
    
See @Li2017, @Arulkumaran2017 and @Mousavi2018 for recent overviews of deep RL. 

The CS294 course of Sergey Levine at Berkeley is incredibly complete: <http://rll.berkeley.edu/deeprlcourse/>. The Reinforcement Learning course by David Silver at UCL covers also the whole field: <http://www0.cs.ucl.ac.uk/staff/d.silver/web/Teaching.html>.

This series of posts from Arthur Juliani <https://medium.com/emergent-future/simple-reinforcement-learning-with-tensorflow-part-0-q-learning-with-tables-and-neural-networks-d195264329d0> also provide a very good introduction to deep RL, associated to code samples using tensorflow.


**Notes**

This document is meant to stay *work in progress* forever, as new algorithms will be added as they are published. Feel free to comment, correct, suggest, pull request by writing to <julien.vitay@informatik.tu-chemnitz.de>.

For some reason, this document is better printed using chrome. Use the single file version [here](./single.html) and print it to pdf. The style is adapted from the Github-Markdown CSS template <https://www.npmjs.com/package/github-markdown-css>. The document is written in Pandoc's Markdown and converted to html using pandoc-citeproc and pandoc-crossref.

Some figures are taken from the original publication ("Taken from" or "Source" in the caption). Their copyright stays to the respective authors, naturally. The rest is my own work and can be reproduced under any free license. 


**Thanks**

Thanks to all the students who helped me dive into that exciting research field, in particular: Winfried Lötzsch, Johannes Jung, Frank Witscher, Danny Hofmann, Oliver Lange, Vinayakumar Murganoor.

<!--PAGEBREAK-->


# Basics

Deep reinforcement learning (deep RL) is the integration of deep learning methods, classically used in supervised or unsupervised learning contexts, with reinforcement learning (RL), a well-studied adaptive control method used in problems with delayed and partial feedback [@Sutton1998]. This section starts with the basics of RL, mostly to set the notations, and provides a quick overview of deep neural networks.

## Reinforcement learning and Markov Decision Process

RL methods apply to problems where an agent interacts with an environment in discrete time steps (@fig:agentenv). At time $t$, the agent is in state $s_t$ and decides to perform an action $a_t$. At the next time step, it arrives in the state $s_{t+1}$ and obtains the reward $r_{t+1}$. The goal of the agent is to maximize the reward obtained on the long term. The textbook by @Sutton1998 (updated in @Sutton2017) defines the field extensively.

![Interaction between an agent and its environment. Taken from @Sutton1998.](img/rl-agent.jpg){#fig:agentenv width=50%}

Reinforcement learning problems are described as **Markov Decision Processes** (MDP) defined by five quantities:

* a state space $\mathcal{S}$ where each state $s$ respects the Markovian property. It can be finite or infinite. 
* an action space $\mathcal{A}$ of actions $a$, which can be finite or infinite, discrete or continuous.
* an initial state distribution $p_0(s_0)$ (from which states is the agent likely to start).
* a transition dynamics model with density $p(s'|s, a)$, sometimes noted $\mathcal{P}_{ss'}^a$. It defines the probability of arriving in the state $s'$ at time $t+1$ when being in the state $s$ and performing the action $a$.
* a reward function $r(s, a, s') : \mathcal{S}\times\mathcal{A}\times\mathcal{S} \rightarrow \Re$ defining the (stochastic) reward obtained after performing $a$ in state $s$ and arriving in $s'$.

The behavior of the agent over time is a **trajectory** (also called episode, history or roll-out) $\tau = (s_0, a_0, s_1, a_, \ldots, s_T, a_T)$ defined by the dynamics of the MDP. Each transition occurs with a probability $p(s'|s, a)$ and provides a certain amount of reward defined by $r(s, a, s')$. In episodic tasks, the horizon $T$ is finite, while in continuing tasks $T$ is infinite. 


Importantly, the **Markovian property** states that:

$$
    p(s_{t+1}|s_t, a_t) = p(s_{t+1}|s_t, a_t, s_{t-1}, a_{t-1}, \dots s_0, a_0)
$$ 

i.e. you do not need the full history of the agent to predict where it will arrive after an action. In simple problems, this is just a question of providing enough information to the description of a state: if a transition depends on what happened in the past, just put that information in the state description.

If the Markov property is not met, RL methods may not converge (or poorly). In many problems, one does not have access to the true states of the agent, but one can only indirectly observe them. For example, in a video game, the true state is defined by a couple of variables: coordinates $(x, y)$ of the two players, position of the ball, speed, etc. However, all you have access to are the raw pixels: sometimes the ball may be hidden behing a wall or a tree, but it still exists in the state space. Speed information is also not observable in a single frame.

In a **Partially Observable Markov Decision Process** (POMDP), observations $o_t$ come from a space $\mathcal{O}$ and are linked to underlying states using the density function $p(o_t| s_t)$. Observations are usually not Markovian, so the full history of observations $h_t = (o_0, a_0, \dots o_t, a_t)$ is needed to solve the problem.

### Policy and value functions

The policy defines the behavior of the agent: which action should be taken in each state. One distinguishes two kinds of policies:

* a stochastic policy $\pi : \mathcal{S} \rightarrow P(\mathcal{A})$ defines the probability distribution $P(\mathcal{A})$ of performing an action.
* a deterministic policy $\mu(s_t)$ is a discrete mapping of $\mathcal{S} \rightarrow \mathcal{A}$.

The policy can be used to explore the environment and generate trajectories of states, rewards and actions. The performance of a policy is determined by calculating the **expected discounted return**, i.e. the sum of all rewards received from time step t onwards: 

$$
    R_t = \sum_{k=0}^{T} \gamma^k \, r_{t+k+1}
$$

where $0 < \gamma \leq 1$ is the discount rate and $r_{t+1}$ represents the reward obtained during the transition from $s_t$ to $s_{t+1}$. 

The **discount rate** $\gamma$ is a critical hyperparameter of RL: chosen too small, only immediate rewards will matter (i.e. participate to $R_t$) and the agent will be greedy. Chosen too close from 1, hypothetical rewards delivered in one year from now will count as much as slightly smaller rewards delivered for certain now. 

If the task is episodic ($T$ is finite, the trajectories ends after a finite number of transitions), $\gamma$ can be set to 1, but if the task is continuing ($T=\infty$, trajectories have no end), $\gamma$ must be chosen smaller than 1.

The Q-value of a state-action pair $(s, a)$ is defined as the expected discounted reward received if the agent takes $a$ from a state $s$ and follows the policy distribution $\pi$ thereafter:

$$
    Q^{\pi}(s, a) = {E}_{\pi}[R_t | s_t = s, a_t=a]
$$

More precisely, the Q-value of a state-action pair is the mathematical expectation of the expected return over all trajectories starting in $(s, a)$ defined by the policy $\pi$. 

Similarly, the value of a state $s$ is the expected discounted reward received if the agent starts in $s$ and thereafter follows its policy $\pi$. 

$$
    V^{\pi}(s) = {E}_{\pi}[R_t | s_t = s]
$$

Obviously, these quantities depend on the states/actions themselves (some chessboard configurations are intrinsically better than others, i.e. you are more likely to win from that state), but also on the policy (if you can kill your opponent in one move - meaning you are in an intrinsically good state - but systematically take the wrong decision and lose, this is actually a bad state).

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

The value of an action depends on which state you arrive in ($s'$), with which probability ($p(s'|s, a)$) this transition occurs, how much reward you receive immediately ($r(s, a, s')$) and how much you will receive later (summarized by $V^\pi(s')$).

Putting together @eq:v-value and @eq:q-value, we obtain the **Bellman equations**:

$$
    V^{\pi}(s) = \sum_{a \in \mathcal{A}} \pi(s, a) \, \sum_{s' \in \mathcal{S}} p(s'|s, a) [r(s, a, s') + \gamma \, V^\pi(s')]
$$

$$
    Q^{\pi}(s, a) = \sum_{s' \in \mathcal{S}} p(s'|s, a) [r(s, a, s') + \gamma \, \sum_{a' \in \mathcal{A}} \pi(s', a') \, Q^\pi(s',a')]
$$

The Bellman equations mean that the value of a state (resp. state-action pair) depends on the value of all other states (resp. state-action pairs), the current policy $\pi$ and the dynamics of the MDP ($p(s'|s, a)$ and $r(s, a, s')$).

![Backup diagrams correponding to the Bellman equations. Taken from @Sutton1998.](img/backup.png){#fig:backup width=50%}

### Dynamic programming

The interesting property of the Bellman equations is that, if the states have the Markovian property, they admit *one and only one* solution. This means that for a given policy, if the dynamics of the MDP are known, it is possible to compute the value of all states or state-action pairs by solving the Bellman equations for all states or state-action pairs (*policy evaluation*). 

Once the values are known for a given policy, it is possible to improve the policy by selecting with the highest probability the action with the highest Q-value. For example, if the current policy chooses the action $a_1$ over $a_2$ in $s$ ($\pi(s, a_1) > \pi(s, a_2)$), but after evaluating the policy it turns out that $Q^\pi(s, a_2) > Q^\pi(s, a_1)$ (the expected return after $a_2$ is higher than after $a_1$), it makes more sense to preferentially select $a_2$, as there is more reward afterwards. We can then create a new policy $\pi'$ where $\pi'(s, a_2) > \pi'(s, a_1)$, which is is *better* policy than $\pi$ as more reward can be gathered after $s$.

![Dynamic programming alternates between policy evaluation and policy improvement. Taken from @Sutton1998.](img/dynamicprogramming.png){#fig:dynamicprogramming width=20%}

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

![Monte-Carlo methods accumulate rewards over a complete episode. Taken from @Sutton1998.](img/unifiedreturn.png){#fig:mc width=50%}

When the environment is *a priori* unknown, it has to be explored in order to build estimates of the V or Q value functions. The key idea of **Monte-Carlo** sampling (MC) is rather simple:

1. Start from a state $s_0$.
2. Perform an episode (sequence of state-action transitions) until a terminal state $s_T$ is reached using your current policy $\pi$.
3. Accumulate the rewards into the actual return for that episode $R_t^{(e)} = \sum_{k=0}^T r_{t+k+1}$ for each time step.
4. Repeat often enough so that the value of a state $s$ can be approximated by the average of many actual returns: 

$$V^\pi(s) = E_\pi[R_t | s_t = s] \approx \frac{1}{M} \sum_{e=1}^M R_t^{(e)}$$

Monte-carlo sampling is a classical method to estimate quantities defined by a mathematical expectation: the *true* value of $V^\pi(s)$ is defined over **all** trajectories starting in $s$, what is impossible to compute in most problems. In MC methods, the true value is approximated by the average of a sufficient number of sampled trajectories, the million dollar question being: what means *sufficient*?

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
    R_t \approx r(s, a, s') + \gamma \, V^\pi(s') \approx r + \gamma \, Q^\pi(s', a')
$$

This gives us the following learning rules:

$$
    V^\pi(s) \leftarrow V^\pi(s) + \alpha (r(s, a, s') + \gamma \, V^\pi(s') - V^\pi(s))
$$

$$
    Q^\pi(s, a) \leftarrow Q^\pi(s, a) + \alpha (r(s, a, s') + \gamma \, Q^\pi(s', a') - Q^\pi(s, a))
$$

The quantity:

$$
 \delta = r(s, a, s') + \gamma \, V^\pi(s') - V^\pi(s)
$$

or:

$$
    \delta = r(s, a, s') + \gamma \, Q^\pi(s', a') - Q^\pi(s, a)
$$

is called the **reward-prediction error** (RPE) or **TD error**: it defines the surprise between the current reward prediction ($V^\pi(s)$ or $Q^\pi(s, a)$) and the sum of the immediate reward plus the reward prediction in the next state / after the next action.

* If $\delta > 0$, the transition was positively surprising: one obtains more reward or lands in a better state than expected. The initial state or action was actually underrated, so its estimated value must be increased.
* If $\delta < 0$, the transition was negatively surprising. The initial state or action was overrated, its value must be decreased.
* If $\delta = 0$, the transition was fully predicted: one obtains as much reward as expected, so the values should stay as they are.

The main advantage of this learning method is that the update of the V- or Q-value can be applied immediately after a transition: no need to wait until the end of an episode, or even to have episodes at all. 

![Temporal difference algorithms update values after a single transition. Taken from @Sutton1998.](img/backup-TD.png){#fig:td width=3%}

When learning Q-values directly, the question is which next action $a'$ should be used in the update rule: the action that will actually be taken for the next transition (defined by $\pi(s', a')$), or the greedy action ($a^* = \text{argmax}_a Q^\pi(s', a)$). This relates to the *on-policy / off-policy* distinction already seen for MC methods:

* *On-policy* TD learning is called **SARSA** (state-action-reward-state-action). It uses the next action sampled from the policy $\pi(s', a')$ to update the current transition. This selected action could be noted $\pi(s')$ for simplicity. It is required that this next action will actually be performed for the next transition. The policy must be $\epsilon$-soft, for example $\epsilon$-greedy or softmax:

$$
    \delta = r(s, a, s') + \gamma \, Q^\pi(s', \pi(s')) - Q^\pi(s, a)
$$

* *Off-policy* TD learning is called **Q-learning** [@Watkins1989]. The greedy action in the next state (the one with the highest Q-value) is used to update the current transition. It does not mean that the greedy action will actually have to be selected for the next transition. The learned policy can therefore also be deterministic:

$$
    \delta = r(s, a, s') + \gamma \, \max_{a'} Q^\pi(s', a') - Q^\pi(s, a)
$$

In Q-learning, the behavior policy has to ensure exploration, while this is achieved implicitely by the learned policy in SARSA, as it must be $\epsilon$-soft. An easy way of building a behavior policy based on a deterministic learned policy is $\epsilon$-greedy: the deterministic action $\mu(s_t)$ is chosen with probability 1 - $\epsilon$, the other actions with probability $\epsilon$. In continuous action spaces, additive noise (e.g. Ohrstein-Uhlenbeck) can be added to the action.

Alternatively, domain knowledge can be used to create the behavior policy and restrict the search to meaningful actions: compilation of expert moves in games, approximate solutions, etc. Again, the risk is that the behavior policy never explores the actually optimal actions.

### Actor-critic architectures

Let's consider the TD error based on state values:

$$
 \delta = r(s, a, s') + \gamma \, V^\pi(s') - V^\pi(s)
$$

As noted in the previous section, the TD error represents how surprisingly good (or bad) a transition between two states has been (ergo the corresponding action). It can be used to update the value of the state $s_t$:

$$
    V^\pi(s) \leftarrow V^\pi(s) + \alpha \, \delta
$$

This allows to estimate the values of all states for the current policy. However, this does not help to 1) directy select the best action or 2) improve the policy. When only the V-values are given, one can only want to reach the next state $V^\pi(s')$ with the highest value: one needs to know which action leads to this better state, i.e. have a model of the environment. Actually, one selects the action with the highest Q-value:

$$
    Q^{\pi}(s, a) = \sum_{s' \in \mathcal{S}} p(s'|s, a) [r(s, a, s') + \gamma \, V^\pi(s')]
$$

An action may lead to a high-valued state, but with such a small probability that it is actually not worth it. $p(s'|s, a)$ and $r(s, a, s')$ therefore have to be known (or at least approximated), what defeats the purpose of sample-based methods.

![Actor-critic architecture [@Sutton1998].](img/actorcritic.png){#fig:actorcritic width=30%}

**Actor-critic** architectures have been proposed to solve this problem:

1. The **critic** learns to estimate the value of a state $V^\pi(s)$ and compute the RPE $\delta = r(s, a, s') + \gamma \, V^\pi(s') - V^\pi(s)$.
2. The **actor** uses the RPE to update a *preference* for the executed action: action with positive RPEs (positively surprising) should be reinforced (i.e. taken again in the future), while actions with negative RPEs should be avoided in the future.

The main interest of this architecture is that the actor can take any form (neural network, decision tree), as long as it able to use the RPE for learning. The simplest actor would be a softmax action selection mechanism, which maintains a *preference* $p(s, a)$ for each action and updates it using the TD error:

$$
    p(s, a) \leftarrow p(s, a) + \alpha \, \delta_t
$$

The policy uses the softmax rule on these preferences:

$$
    \pi(s, a) = \frac{p(s, a)}{\sum_a p(s, a)}
$$

Actor-critic algorithms learn at the same time two aspects of the problem:

* A value function (e.g. $V^\pi(s)$) to compute the TD error in the critic,
* A policy $\pi$ in the actor.

Classical TD learning only learn a value function ($V^\pi(s)$ or $Q^\pi(s, a)$): these methods are called **value-based** methods. Actor-critic architectures are particularly important in **policy-based** methods (see @sec:policy-gradient-methods).

### Function approximation 

All the methods presented before are *tabular methods*, as one needs to store one value per state-action pair: either the Q-value of the action or a preference for that action. In most useful applications, the number of values to store would quickly become redhibitory: when working on raw images, the number of possible states alone is untractable. Moreover, these algorithms require that each state-action pair is visited a sufficient number of times to converge towards the optimal policy: if a single state-action pair is never visited, there is no guarantee that the optimal policy will be found. The problem becomes even more obvious when considering *continuous* state or action spaces.

However, in a lot of applications, the optimal action to perform in two very close states is likely to be the same: changing one pixel in a video game does not change which action should be applied. It would therefore be very useful to be able to *interpolate* Q-values between different states: only a subset of all state-action pairs has to explored; the others will be "guessed" depending on the proximity between the states and/or the actions. The problem is now **generalization**, i.e. transferring acquired knowledge to unseen but similar situations.

This is where **function approximation** becomes useful: the Q-values or the policy are not stored in a table, but rather learned by a function approximator. The type of function approximator does not really matter here: in deep RL we are of course interested in deep neural networks (@sec:deep-learning), but any kind of regressor theoretically works (linear algorithms, radial-basis function network, SVR...).

#### Value-based function approximation {-}

In **value-based** methods, we want to approximate the Q-values $Q^\pi(s,a)$ of all possible state-action pairs for a given policy. The function approximator depends on a set of parameters $\theta$. $\theta$ can for example represent all the weights and biases of a neural network. The approximated Q-value can now be noted $Q(s, a ;\theta)$ or $Q_\theta(s, a)$. As the parameters will change over time during learning, we can omit the time $t$ from the notation. Similarly, action selection is usually $\epsilon$-greedy or softmax, so the policy $\pi$ depends directly on the estimated Q-values and can therefore on the parameters: it is noted $\pi_\theta$.

![Function approximators can either take a state-action pair as input and output the Q-value, or simply take a state as input and output the Q-values of all possible actions.](img/functionapprox.png){#fig:functionapprox width=50%}

There are basically two options regarding the structure of the function approximator (@fig:functionapprox):

1. The approximator takes a state-action pair $(s, a)$ as input and returns a single Q-value $Q(s, a)$.
2. It takes a state $s$ as input and returns the Q-value of all possible actions in that state.

The second option is of course only possible when the action space is discrete, but has the advantage to generalize better over similar states.

The goal of a function approximator is to minimize a *loss function* (or cost function) $\mathcal{L}(\theta)$, so that the estimated Q-values converge for all state-pairs towards their target value, depending on the chosen algorithm:

* Monte-Carlo methods: the Q-value of each $(s, a)$ pair should converge towards the mean expected return (in expectation):

$$
    \mathcal{L}(\theta) = E_\pi[(R_t - Q_\theta(s, a))^2]
$$ 

If we learn over $N$ episodes of length $T$, the loss function can be approximated as:

$$
    \mathcal{L}(\theta) \approx \frac{1}{N} \sum_{e=1}^M \sum_{t = 1}^T [R^e_t - Q_\theta(s_t, a_t)]^2
$$ 

* Temporal difference methods: the Q-values should converge towards an estimation of the mean expected return. 
    
    * For SARSA:

    $$
    \mathcal{L}(\theta) = E_\pi[(r(s, a, s') + \gamma \, Q_\theta(s', \pi(s')) - Q_\theta(s, a))^2]
    $$

    * For Q-learning:

    $$
    \mathcal{L}(\theta) = E_\pi[(r(s, a, s') + \gamma \, \max_{a'} Q_\theta(s', a') - Q_\theta(s, a))^2]
    $$

Any function approximator able to minimize these loss functions can be used. 

#### Policy-based function approximation {-}

In policy-based function approximation, we want to directly learn a policy $\pi_\theta(s, a)$ that maximizes the expected return of each possible transition, i.e. the ones which are selected by the policy. The **objective function** to be maximized is defined over all trajectories $\tau = (s_0, a_0, s_1, a_1, \ldots, s_T, a_T)$ conditioned by the policy:

$$
    J(\theta) = {E}_{\tau \sim \pi_\theta} [R_t]
$$

In short, the learned policy $\pi_\theta$ should only produce trajectories $\tau$ where each state is associated to a high expected return $R_t$ and avoid trajectories with low expected returns. Although this objective function leads to the desired behaviour, it is not computationally tractable as we would need to integrate over all possible trajectories. The methods presented in @sec:policy-gradient-methods will provide estimates of the gradient of this objective function.


<!--PAGEBREAK-->



## Deep learning

Deep RL uses deep neural networks as function approximators, allowing complex representations of the value of state-action pairs to be learned. This section provides a very quick overview of deep learning. For additional details, refer to the excellent book of @Goodfellow2016.

### Deep neural networks

A deep neural network (DNN) consists of one input layer $\mathbf{x}$, one or several hidden layers $\mathbf{h_1}, \mathbf{h_2}, \ldots, \mathbf{h_n}$ and one output layer $\mathbf{y}$ (@fig:dnn).

![Architecture of a deep neural network. Figure taken from @Nielsen2015, CC-BY-NC.](img/dnn.png){#fig:dnn width=60%}

Each layer $k$ (called *fully-connected*) transforms the activity of the previous layer (the vector $\mathbf{h_{k-1}}$) into another vector $\mathbf{h_{k}}$ by multiplying it with a **weight matrix** $W_k$, adding a **bias** vector $\mathbf{b_k}$ and applying a non-linear **activation function** $f$.

$$
    \mathbf{h_{k}} = f(W_k \times \mathbf{h_{k-1}} + \mathbf{b_k})
$${#eq:fullyconnected}

The activation function can theoretically be of any type as long as it is non-linear (sigmoid, tanh...), but modern neural networks use preferentially the **Rectified Linear Unit** (ReLU) function $f(x) = \max(0, x)$ or its parameterized variants.

The goal of learning is to find the weights and biases $\theta$ minimizing a given **loss function** on a training set $\mathcal{D}$. 

* In *regression* problems, the **mean square error** (mse) is minimized:

$$
    \mathcal{L}(\theta) = E_{\mathbf{x}, \mathbf{t} \in \mathcal{D}} [||\mathbf{t} - \mathbf{y}||^2]
$$

where $\mathbf{x}$ is the input, $\mathbf{t}$ the true output (defined in the training set) and $\mathbf{y}$ the prediction of the NN for the input $\mathbf{x}$. The closer the prediction from the true value, the smaller the mse.

* In *classification* problems, the **cross entropy** (or negative log-likelihood) is minimized:

$$
    \mathcal{L}(\theta) = - E_{\mathbf{x}, \mathbf{t} \in \mathcal{D}} [\sum_i t_i \log y_i]
$$

where the log-likelihood of the prediction $\mathbf{y}$ to match the data $\mathbf{t}$ is maximized over the training set. The mse could be used for classification problems too, but the output layer usually has a softmax activation function for classification problems, which works nicely with the cross entropy loss function. See <https://rdipietro.github.io/friendly-intro-to-cross-entropy-loss> for the link between cross entropy and log-likelihood and <https://deepnotes.io/softmax-crossentropy> for the interplay between softmax and cross entropy.

Once the loss function is defined, it has to be minimized by searching optimal values for the free parameters $\theta$. This optimization procedure is based on **gradient descent**, which is an iterative procedure modifying estimates of the free parameters in the opposite direction of the gradient of the loss function:

$$
\Delta \theta = -\eta \, \nabla_\theta \mathcal{L}(\theta) = -\eta \, \frac{\partial \mathcal{L}(\theta)}{\partial \theta}
$$

The learning rate $\eta$ is chosen very small to ensure a smooth convergence. Intuitively, the gradient (or partial derivative) represents how the loss function changes when each parameter is slightly increased. If the gradient w.r.t a single parameter (e.g. a weight $w$) is positive, increasing the weight increases the loss function (i.e. the error), so the weight should be slightly decreased instead. If the gradient is negative, one should increase the weight.

The question is now to compute the gradient of the loss function w.r.t all the parameters of the DNN, i.e. each single weight and bias. The solution is given by the **backpropagation** algorithm, which is simply an application of the **chain rule** to feedforward neural networks:

$$
    \frac{\partial \mathcal{L}(\theta)}{\partial W_k} = \frac{\partial \mathcal{L}(\theta)}{\partial \mathbf{y}} \times \frac{\partial \mathbf{y}}{\partial \mathbf{h_n}} \times \frac{\partial \mathbf{h_n}}{\partial \mathbf{h_{n-1}}} \times \ldots \times \frac{\partial \mathbf{h_k}}{\partial W_k}
$$

Each layer of the network adds a contribution to the gradient when going **backwards** from the loss function to the parameters. Importantly, all functions used in a NN are differentiable, i.e. those partial derivatives exist (and are easy to compute). For the fully connected layer represented by @eq:fullyconnected, the partial derivative is given by:

$$
    \frac{\partial \mathbf{h_{k}}}{\partial \mathbf{h_{k-1}}} = f'(W_k \times \mathbf{h_{k-1}} + \mathbf{b_k}) \, W_k
$$

and its dependency on the parameters is:

$$
    \frac{\partial \mathbf{h_{k}}}{\partial W_k} = f'(W_k \times \mathbf{h_{k-1}} + \mathbf{b_k}) \, \mathbf{h_{k-1}}
$$
$$
    \frac{\partial \mathbf{h_{k}}}{\partial \mathbf{b_k}} = f'(W_k \times \mathbf{h_{k-1}} + \mathbf{b_k})
$$

Activation functions are chosen to have an easy-to-compute derivative, such as the ReLU function:

$$
    f'(x) = \begin{cases} 1 \quad \text{if} \quad x > 0 \\ 0 \quad \text{otherwise.} \end{cases}
$$

Partial derivatives are automatically computed by the underlying libraries, such as tensorflow, theano, pytorch, etc. The next step is choose an **optimizer**, i.e. a gradient-based optimization method allow to modify the free parameters using the gradients. Optimizers do not work on the whole training set, but use **minibatches** (a random sample of training examples: their number is called the *batch size*) to compute iteratively the loss function. The most popular optimizers are:

* SGD (stochastic gradient descent): vanilla gradient descent on random minibatches.
* SGD with momentum (Nesterov or not): additional momentum to avoid local minima of the loss function.
* Adagrad
* Adadelta
* RMSprop
* Adam
* Many others. Check the doc of keras to see what is available: <https://keras.io/optimizers> 

See this useful post for a comparison of the different optimizers: <http://ruder.io/optimizing-gradient-descent> [@Ruder2016]. The common wisdom is that SGD with Nesterov momentum works best (i.e. it finds a better minimum) but its meta-parameters (learning rate, momentum) are hard to find, while Adam works out-of-the-box, at the cost of a slightly worse minimum. For deep RL, Adam is usually preferred, as the goal is to quickly find a working solution, not to optimize it to the last decimal.

<!-- ![Comparison of different optimizers. Source: @Ruder2016, <http://ruder.io/optimizing-gradient-descent>.](img/optimizers.gif){#fig:optimizers width=50%} -->

Additional regularization mechanisms are now typically part of DNNs in order to avoid overfitting (learning by heart the training set but failing to generalize): L1/L2 regularization, dropout, batch normalization, etc. Refer to @Goodfellow2016 for further details.

### Convolutional networks

Convolutional Neural Networks (CNN) are an adaptation of DNNs to deal with highly dimensional input spaces such as images. The idea is that neurons in the hidden layer reuse ("share") weights over the input image, as the features learned by early layers are probably local in visual classification tasks: in computer vision, an edge can be detected by the same filter all over the input image. 

A **convolutional layer** learns to extract a given number of features (typically 16, 32, 64, etc) represented by 3x3 or 5x5 matrices. These matrices are then convoluted over the whole input image (or the previous convolutional layer) to produce **feature maps**. If the input image has a size NxMx1 (grayscale) or NxMx3 (colored), the convolutional layer will be a tensor of size NxMxF, where F is the number of extracted features. Padding issues may reduce marginally the spatial dimensions. One important aspect is that the convolutional layer is fully differentiable, so backpropagation and the usual optimizers can be used to learn the filters.

![Convolutional layer. Source: <https://github.com/vdumoulin/conv_arithmetic>.](img/convlayer.gif){#fig:convlayer width=50%}

After a convolutional layer, the spatial dimensions are preserved. In classification tasks, it does not matter where the object is in the image, the only thing that matters is what it is: classification requires **spatial invariance** in the learned representations. The **max-pooling layer** was introduced to downsample each feature map individually and increase their spatial invariance. Each feature map is divided into 2x2 blocks (generally): only the maximal feature activation in that block is preserved in the max-pooling layer. This reduces the spatial dimensions by a factor two in each direction, but keeps the number of features equal.

![Max-pooling layer. Source: Stanford's CS231n course <http://cs231n.github.io/convolutional-networks>](img/maxpooling.png){#fig:maxpooling}

A convolutional neural network is simply a sequence of convolutional layers and max-pooling layers (sometime two convolutional layers are applied in a row before max-pooling, as in VGG [@Simonyan2014]), followed by a couple of fully-connected layers and a softmax output layer. @fig:alexnet shows the architecture of AlexNet, the winning architecture of the ImageNet challenge in 2012 [@Krizhevsky2012].

![Architecture of the AlexNet CNN. Taken from @Krizhevsky2012.](img/alexnet.png){#fig:alexnet}

Many improvements have been proposed since 2012 (e.g. ResNets [@He2015]) but the idea stays similar. Generally, convolutional and max-pooling layers are alternated until the spatial dimensions are so reduced (around 10x10) that they can be put into a single vector and fed into a fully-connected layer. This is **NOT** the case in deep RL! Contrary to object classification, spatial information is crucial in deep RL: position of the ball, position of the body, etc. It matters whether the ball is to the right or to the left of your paddle when you decide how to move it. Max-pooling layers are therefore omitted and the CNNs only consist of convolutional and fully-connected layers. This greatly increases the number of weights in the networks, hence the number of training examples needed to train the network. This is still the main limitation of using CNNs in deep RL.

### Recurrent neural networks

Feedforward neural networks learn to efficiently map static inputs $\mathbf{x}$ to outputs $\mathbf{y}$ but have no memory or context: the output at time $t$ does not depend on the inputs at time $t-1$ or $t-2$, only the one at time $t$. This is problematic when dealing with video sequences for example: if the task is to classify videos into happy/sad, a frame by frame analysis is going to be inefficient (most frames a neutral). Concatenating all frames in a giant input vector would increase dramatically the complexity of the classifier and no generalization can be expected.

Recurrent Neural Networks (RNN) are designed to deal with time-varying inputs, where the relevant information to take a decision at time $t$ may have happened at different times in the past. The general structure of a RNN is depicted on @fig:rnn:

![Architecture of a RNN. Left: recurrent architecture. Right: unrolled network, showing that a RNN is equivalent to a deep network. Taken from <http://colah.github.io/posts/2015-08-Understanding-LSTMs>.](img/RNN-unrolled.png){#fig:rnn width=90%}

The output $\mathbf{h}_t$ of the RNN at time $t$ depends on its current input $\mathbf{x}_t$, but also on its previous output $\mathbf{h}_{t-1}$, which, by recursion, depends on the whole history of inputs $(x_0, x_1, \ldots, x_t)$. 

$$
    \mathbf{h}_t = f(W_x \, \mathbf{x}_{t} + W_h \, \mathbf{h}_{t-1} + \mathbf{b})
$$

Once unrolled, a RNN is equivalent to a deep network, with $t$ layers of weights between the first input $\mathbf{x}_0$ and the current output $\mathbf{h}_t$. The only difference with a feedforward network is that weights are reused between two time steps / layers. **Backpropagation though time** (BPTT) can be used to propagate the gradient of the loss function backwards in time and learn the weights $W_x$ and $W_h$ using the usual optimizer (SGD, Adam...).

However, this kind of RNN can only learn short-term dependencies because of the **vanishing gradient problem** [@Hochreiter1991]. When the gradient of the loss funcion travels backwards from  $\mathbf{h}_t$ to $\mathbf{x}_0$, it will be multiplied $t$ times by the recurrent weights $W_h$. If $|W_h| > 1$, the gradient will explode with increasing $t$, while if $|W_h| < 1$, the gradient will vanish to 0. 

The solution to this problem is provided by **long short-term memory networks** [LSTM;@Hochreiter1997]. LSTM layers maintain additionally a state $\mathbf{C}_t$ (also called context or memory) which is manipulated by three learnable gates (input, forget and output gates). As in regular RNNs, a *candidate state* $\tilde{\mathbf{C}_t}$ is computed based on the current input and the previous output:

$$
    \tilde{\mathbf{C}_t} = f(W_x \, \mathbf{x}_{t} + W_h \, \mathbf{h}_{t-1} + \mathbf{b})
$$

![Architecture of a LSTM layer. Taken from <http://colah.github.io/posts/2015-08-Understanding-LSTMs>.](img/LSTM.png){#fig:lstm width=40%}

The activation function $f$ is usually a tanh function. The input and forget learn to decide how the candidate state should be used to update the current state:

* The input gate decides which part of the candidate state $\tilde{\mathbf{C}_t}$ will be used to update the current state $\mathbf{C}_t$:

$$
    \mathbf{i}_t = \sigma(W^i_x \, \mathbf{x}_{t} + W^i_h \, \mathbf{h}_{t-1} + \mathbf{b}^i)
$$

The sigmoid activation function $\sigma$ is used to output a number between 0 and 1 for each neuron: 0 means the candidate state will not be used at all, 1 means completely. 

* The forget gate decides which part of the current state should be kept or forgotten:

$$
    \mathbf{f}_t = \sigma(W^f_x \, \mathbf{x}_{t} + W^f_h \, \mathbf{h}_{t-1} + \mathbf{b}^f)
$$

Similarly, 0 means taht the corresponding element of the current state will be erased, 1 that it will be kept.

Once the input and forget gates are computed, the current state can be updated based on its previous value and the candidate state:

$$
   \mathbf{C}_t =  \mathbf{i}_t \odot \tilde{\mathbf{C}_t} + \mathbf{f}_t \odot \mathbf{C}_{t-1}
$$

where $\odot$ is the element-wise multiplication.

* The output gate finally learns to select which part of the current state $\mathbf{C}_t$ should be used to produce the current output $\mathbf{h}_t$:

$$
    \mathbf{o}_t = \sigma(W^o_x \, \mathbf{x}_{t} + W^o_h \, \mathbf{h}_{t-1} + \mathbf{b}^o)
$$

$$
    \mathbf{h}_t = \mathbf{o}_t \odot \tanh \mathbf{C}_t
$$

The architecture may seem complex, but everything is differentiable: backpropagation though time can be used to learn not only the input and recurrent weights for the candidate state, but also the weights and and biases of the gates. The main advantage of LSTMs is that they solve the vanishing gradient problem: if the input at time $t=0$ is important to produce a response at time $t$, the input gate will learn to put it into the memory and the forget gate will learn to maintain in the current state until it is not needed anymore. During this "working memory" phase, the gradient is multiplied by exactly one as nothing changes: the dependency can be learned with arbitrary time delays!

There are alternatives to the classical LSTM layer such as the gated recurrent unit [GRU; @Cho2014] or peephole connections [@Gers2001]. See <http://colah.github.io/posts/2015-08-Understanding-LSTMs>, <https://medium.com/mlreview/understanding-lstm-and-its-diagrams-37e2f46f1714> or <http://blog.echen.me/2017/05/30/exploring-lstms/> for more visual explanations of LSTMs and their variants.

RNNs are particularly useful for deep RL when considering POMDPs, i.e. partially observable problems. If an observation does not contain enough information about the underlying state (e.g. a single image does not contain speed information), LSTM can integrate these observations over time and learn to implicitely represent speed in its context vector, allowing efficient policies to be learned.


<!--PAGEBREAK-->


# Value-based methods

## Limitations of deep neural networks for function approximation

The goal of value-based deep RL is to approximate the Q-value of each possible state-action pair using a deep (convolutional) neural network. As shown on @fig:functionapprox, the network can either take a state-action pair as input and return a single output value, or take only the state as input and return the Q-value of all possible actions (only possible if the action space is discrete), In both cases, the goal is to learn estimates $Q_\theta(s, a)$ with a NN with parameters $\theta$.

![Function approximators can either associate a state-action pair $(s, a)$ to its Q-value (left), or associate a state $s$ to the Q-avlues of all actions possible in that state (right).](img/functionapprox.png){width=40%}

When using Q-learning, we have already seen in @sec:function-approximation that the problem is a regression problem, where the following mse loss function has to be minimized:

$$
    \mathcal{L}(\theta) = E_\pi[(r_t + \gamma \, \max_{a'} Q_\theta(s', a') - Q_\theta(s, a))^2]
$$

In short, we want to reduce the prediction error, i.e. the mismatch between the estimate of the value of an action $Q_\theta(s, a)$ and the real expected return, here approximated with $r(s, a, s') + \gamma \, \text{max}_{a'} Q_\theta(s', a')$.

We can compute this loss by gathering enough samples $(s, a, r, s')$ (i.e. single transitions), concatenating them randomly in minibatches, and let the DNN learn to minimize the prediction error using backpropagation and SGD, indirectly improving the policy. The following pseudocode would describe the training procedure when gathering transitions **online**, i.e. when directly interacting with the environment:

---

* Initialize value network $Q_{\theta}$ with random weights.
* Initialize empty minibatch $\mathcal{D}$ of maximal size $n$.
* Observe the initial state $s_0$.
* for $t \in [0, T_\text{total}]$:
    * Select the action $a_t$ based on the behaviour policy derived from $Q_\theta(s_t, a)$ (e.g. softmax).
    * Perform the action $a_t$ and observe the next state $s_{t+1}$ and the reward $r_{t+1}$.
    * Predict the Q-value of the greedy action in the next state $\max_{a'} Q_\theta(s_{t+1}, a')$
    * Store $(s_t, a_t, r_{t+1} + \gamma \, \max_{a'} Q_\theta(s_{t+1}, a'))$ in the minibatch.
    * If minibatch $\mathcal{D}$ is full:
        * Train the value network $Q_{\theta}$ on $\mathcal{D}$ to minimize $\mathcal{L}(\theta) = E_\mathcal{D}[(r(s, a, s') + \gamma \, \text{max}_{a'} Q_\theta(s', a') - Q_\theta(s, a))^2]$
        * Empty the minibatch $\mathcal{D}$.

---

However, the definition of the loss function uses the mathematical expectation operator $E$ over all transitions, which can only be approximated by **randomly** sampling the distribution (the MDP). This implies that the samples concatenated in a minibatch should be independent from each other (i.i.d). When gathering transitions online, the samples are correlated: $(s_t, a_t, r_{t+1}, s_{t+1})$ will be followed by $(s_{t+1}, a_{t+1}, r_{t+2}, s_{t+2})$, etc. When playing video games, two successive frames will be very similar (a few pixels will change, or even none if the sampling rate is too high) and the optimal action will likely not change either (to catch the ball in pong, you will need to perform the same action - going left - many times in a row).

**Correlated inputs/outputs** are very bad for deep neural networks: the DNN will overfit and fall into a very bad local minimum. That is why stochastic gradient descent works so well: it randomly samples values from the training set to form minibatches and minimize the loss function on these uncorrelated samples (hopefully). If all samples of a minibatch were of the same class (e.g. zeros in MNIST), the network would converge poorly. This is the first problem preventing an easy use of deep neural networks as function approximators in RL.

The second major problem is the **non-stationarity** of the targets in the loss function. In classification or regression, the desired values $\mathbf{t}$ are fixed throughout learning: the class of an object does not change in the middle of the training phase.

$$
    \mathcal{L}(\theta) = - E_{\mathbf{x}, \mathbf{t} \in \mathcal{D}}[ ||\mathbf{t} - \mathbf{y}||^2]
$$

In Q-learning, the target $r(s, a, s') + \gamma \, \max_{a'} Q_\theta(s', a')$ will change during learning, as $Q_\theta(s', a')$ depends on the weights $\theta$ and will hopefully increase as the performance improves. This is the second problem of deep RL: deep NN are particularly bad on non-stationary problems, especially feedforward networks. They iteratively converge towards the desired value, but have troubles when the target also moves (like a dog chasing its tail).

## Deep Q-Network (DQN)

@Mnih2015 (originally arXived in @Mnih2013) proposed an elegant solution to the problems of correlated inputs/outputs and non-stationarity inherent to RL. This article is a milestone of deep RL and it is fair to say that it started or at least strongly renewed the interest for deep RL.

The first idea proposed by @Mnih2015 solves the problem of correlated input/outputs and is actually quite simple: instead of feeding successive transitions into a minibatch and immediately training the NN on it, transitions are stored in a huge buffer called **experience replay memory** (ERM) or **replay buffer** able to store 100000 transitions. When the buffer is full, new transitions replace the old ones. SGD can now randomly sample the ERM to form minibatches and train the NN.

![Experience replay memory. Interactions with the environment are stored in the ERM. Random minibatches are sampled from it to train the DQN value network.](img/ERM.png){#fig:erm width=40%}

The second idea solves the non-stationarity of the targets $r(s, a, s') + \gamma \, \max_{a'} Q_\theta(s', a')$. Instead of computing it with the current parameters $\theta$ of the NN, they are computed with an old version of the NN called the **target network** with parameters $\theta'$. The target network is updated only infrequently (every thousands of iterations or so) with the learned weights $\theta$. As this target network does not change very often, the targets stay constant for a long period of time, and the problem becomes more stationary.

The resulting algorithm is called **Deep Q-Network (DQN)**. It is summarized by the following pseudocode:

---

* Initialize value network $Q_{\theta}$ with random weights.
* Copy $Q_{\theta}$ to create the target network $Q_{\theta'}$.
* Initialize experience replay memory $\mathcal{D}$ of maximal size $N$.
* Observe the initial state $s_0$.
* for $t \in [0, T_\text{total}]$:
    * Select the action $a_t$ based on the behaviour policy derived from $Q_\theta(s_t, a)$ (e.g. softmax).
    * Perform the action $a_t$ and observe the next state $s_{t+1}$ and the reward $r_{t+1}$.
    * Store $(s_t, a_t, r_{t+1}, s_{t+1})$ in the experience replay memory.
    * Every $T_\text{train}$ steps:
        * Sample a minibatch $\mathcal{D}_s$ randomly from $\mathcal{D}$.
        * For each transition $(s, a, r, s')$ in the minibatch:            
            * Predict the Q-value of the greedy action in the next state $\max_{a'} Q_{\theta'}(s', a')$ using the target network.
            * Compute the target value $y = r + \gamma \, \max_{a'} Q_{\theta'}(s', a')$.
        * Train the value network $Q_{\theta}$ on $\mathcal{D}_s$ to minimize $\mathcal{L}(\theta) = E_{\mathcal{D}_s}[(y - Q_\theta(s, a))^2]$
    * Every $T_\text{target}$ steps:
        * Update the target network with the trained value network:  $\theta' \leftarrow \theta$

---

In this document, pseudocode will omit many details to simplify the explanations (for example here, the case where a state is terminal - the game ends - and the next state has to be chosen from the distribution of possible starting states). Refer to the original publication for more exact algorithms.

The first thing to notice is that experienced transitions are not immediately used for learning, but simply stored in the ERM to be sampled later. Due to the huge size of the ERM, it is even likely that the recently experienced transition will only be used for learning hundreds or thousands of steps later. Meanwhile, very old transitions, generated using an initially bad policy, can be used to train the network for a very long time.

The second thing is that the target network is not updated very often ($T_\text{target}=10000$), so the target values are going to be wrong a long time. More recent algorithms such as DDPG (@sec:deep-deterministic-policy-gradient-ddpg) use a a smoothed version of the current weights, as proposed in @Lillicrap2015:

$$
    \theta' = \tau \, \theta + (1-\tau) \, \theta'
$$ 

If this rule is applied after each step with a very small rate $\tau$, the target network will slowly track the learned network, but never be the same.

These two facts make DQN extremely slow to learn: millions of transitions are needed to obtain a satisfying policy. This is called the **sample complexity**, i.e. the number of transitions needed to obtain a satisfying performance. DQN finds very good policies, but at the cost of a very long training time.

DQN was initially applied to solve various Atari 2600 games. Video frames were used as observations and the set of possible discrete actions was limited (left/right/up/down, shoot, etc). The CNN used is depicted on @fig:dqn. It has two convolutional layers, no max-pooling, 2 fully-connected layer and one output layer representing the Q-value of all possible actions in the games.

![Architecture of the CNN used in the original DQN paper. Taken from @Mnih2015.](img/dqn.png){#fig:dqn}

The problem of partial observability is solved by concatenating the four last video frames into a single tensor used as input to the CNN. The convolutional layers become able through learning to extract the speed information from it. Some of the Atari games (Pinball, Breakout) were solved with a performance well above human level, especially when they are mostly reactive. Games necessitating more long-term planning (Montezuma' Revenge) were still poorly learned, though.

Beside being able to learn using delayed and sparse rewards in highly dimensional input spaces, the true *tour de force* of DQN is that it was able to learn the 49 Atari games in a row, using the same architecture and hyperparameters, and without resetting the weights between two games: knowledge acquired in one game could be reused for the next game. This created great excitement, as the ability to reuse knowledge over different tasks is a fundamental property of true intelligence.

## Double DQN

In DQN, the experience replay memory and the target network were decisive in allowing the CNN to learn the tasks through RL. Their drawback is that they drastically slow down learning and increase the sample complexity. Additionally, DQN has stability issues: the same network may not converge the same way in different runs. One first improvement on DQN was proposed by @vanHasselt2015 and called **double DQN**.

The idea is that the target value $y = r(s, a, s') + \gamma \, \max_{a'} Q_{\theta'}(s', a')$ is frequently over-estimating the true expected return because of the max operator. Especially at the beginning of learning when Q-values are far from being correct, if an action is over-estimated ($Q_{\theta'}(s', a)$ is higher that its true value) and selected by the target network as the next greedy action, the learned Q-value $Q_{\theta}(s, a)$ will also become over-estimated, what will propagate to all previous actions on the long-term. @vanHasselt2010 showed that this over-estimation is inevitable in regular Q-learning and proposed **double learning**.

The idea is to train independently two value networks: one will be used to find the greedy action (the action with the maximal Q-value), the other to estimate the Q-value itself. Even if the first network choose an over-estimated action as the greedy action, the other might provide a less over-estimated value for it, solving the problem.

Applying double learning to DQN is particularly straightforward: there are already two value networks, the trained network and the target network. Instead of using the target network to both select the greedy action in the next state and estimate its Q-value, here the trained network $\theta$ is used to select the greedy action $a^* = \text{argmax}_{a'} Q_\theta (s', a')$ while the target network only estimates its Q-value. The target value becomes:

$$
    y = r(s, a, s') + \gamma \, Q_{\theta'}(s', \text{argmax}_{a'} Q_\theta (s', a')) 
$$

This induces only a small modification of the DQN algorithm and significantly improves its performance and stability:

---

* Every $T_\text{train}$ steps:
    * Sample a minibatch $\mathcal{D}_s$ randomly from $\mathcal{D}$.
    * For each transition $(s, a, r, s')$ in the minibatch:
        * Select the greedy action in the next state $a^* = \text{argmax}_{a'} Q_\theta (s', a')$ using the trained network.     
        * Predict its Q-value $Q_{\theta'}(s', a^*)$ using the target network.
        * Compute the target value $y = r + \gamma \, Q_{\theta'}(s', a*)$.

---


## Prioritised replay

Another drawback of the original DQN is that the experience replay memory is sampled uniformly. Novel and interesting transitions are selected with the same probability as old well-predicted transitions, what slows down learning. The main idea of **prioritized replay** [@Schaul2015] is to order the transitions in the experience replay memory in decreasing order of their TD error:

$$
    \delta = r(s, a, s') + \gamma \, Q_{\theta'}(s', \text{argmax}_{a'} Q_\theta (s', a')) - Q_\theta(s, a)
$$

and sample with a higher probability those surprising transitions to form a minibatch. However, non-surprising transitions might become relevant again after enough training, as the $Q_\theta(s, a)$ change, so prioritized replay has a softmax function over the TD error to ensure "exploration" of memorized transitions. This data structure has of course a non-negligeable computational cost, but accelerates learning so much that it is worth it. See <https://jaromiru.com/2016/11/07/lets-make-a-dqn-double-learning-and-prioritized-experience-replay/> for a presentation of double DQN with prioritized replay.

## Duelling network

The classical DQN architecture uses a single NN to predict directly the value of all possible actions $Q_\theta(s, a)$. The value of an action depends on two factors:

* the value of the underlying state $s$: in some states, all actions are bad, you lose whatever you do.
* the interest of that action: some actions are better than others for a given state.

This leads to the definition of the **advantage** $A^\pi(s,a)$ of an action:

$$
    A^\pi(s, a) = Q^\pi(s, a) - V^\pi(s)
$${#eq:advantagefunction}

The advantage of the optimal action in $s$ is equal to zero: the expected return in $s$ is the same as the expected return when being in $s$ and taking $a$, as the optimal policy will choose $a$ in $s$ anyway. The advantage of all other actions is negative: they bring less reward than the optimal action (by definition), so they are less advantageous. Note that this is only true if your estimate of $V^\pi(s)$ is correct.

@Baird1993 has shown that it is advantageous to decompose the Q-value of an action into the value of the state and the advantage of the action (*advantage updating*):


$$
    Q^\pi(s, a) = V^\pi(s) + A^\pi(s, a)
$$

If you already know that the value of a state is very low, you do not need to bother exploring and learning the value of all actions in that state, they will not bring much. Moreover, the advantage function has **less variance** than the Q-values, which is a very good property when using neural networks for function approximation. The variance of the Q-values comes from the fact that they are estimated based on other estimates, which themselves evolve during learning (non-stationarity of the targets) and can drastically change during exploration (stochastic policies). The advantages only track the *relative* change of the value of an action compared to its state, what is going to be much more stable over time.


The range of values taken by the advantages is also much smaller than the Q-values. Let's suppose we have two states with values -10 and 10, and two actions with advantages 0 and -1 (it does not matter which one). The Q-values will vary between -11 (the worst action in the worst state) and 10 (the best action in the best state), while the advantage only varies between -1 and 0. It is therefore going to be much easier for a neural network to learn the advantages than the Q-values, as they are theoretically not bounded.



![Duelling network architecture. Top: classical feedforward architecture to predict Q-values. Bottom: Duelling networks predicting state values and advantage functions to form the Q-values. Taken from @Wang2016.](img/duelling.png){#fig:duelling width=60%}

@Wang2016 incorporated the idea of *advantage updating* in a double DQN architecture with prioritized replay (@fig:duelling). As in DQN, the last layer represents the Q-values of the possible actions and has to minimize the mse loss:

$$
    \mathcal{L}(\theta) = E_\pi([r(s, a, s') + \gamma \, Q_{\theta', \alpha', \beta'}(s', \text{argmax}_{a'} Q_{\theta, \alpha, \beta} (s', a')) - Q_{\theta, \alpha, \beta}(s, a)]^2)
$$ 

The difference is that the previous fully-connected layer is forced to represent the value of the input state $V_{\theta, \beta}(s)$ and the advantage of each action $A_{\theta, \alpha}(s, a)$ separately. There are two separate sets of weights in the network, $\alpha$ and $\beta$, to predict these two values, sharing  representations from the early convolutional layers through weights $\theta$. The output layer performs simply a parameter-less summation of both sub-networks:

$$
    Q_{\theta, \alpha, \beta}(s, a) = V_{\theta, \beta}(s) + A_{\theta, \alpha}(s, a)
$$

The issue with this formulation is that one could add a constant to $V_{\theta, \beta}(s)$ and substract it from $A_{\theta, \alpha}(s, a)$ while obtaining the same result. An easy way to constrain the summation is to normalize the advantages, so that the greedy action has an advantage of zero as expected:

$$
    Q_{\theta, \alpha, \beta}(s, a) = V_{\theta, \beta}(s) + (A_{\theta, \alpha}(s, a) - \max_a A_{\theta, \alpha}(s, a))
$$

By doing this, the advantages are still free, but the state value will have to take the correct valu. @Wang2016 found that it is actually better to replace the $\max$ operator by the mean of the advantages. In this case, the advantages only need to change as fast as their mean, instead of having to compensate quickly for any change in the greedy action as the policy improves:

$$
    Q_{\theta, \alpha, \beta}(s, a) = V_{\theta, \beta}(s) + (A_{\theta, \alpha}(s, a) - \frac{1}{|\mathcal{A}|} \sum_a A_{\theta, \alpha}(s, a))
$$

Apart from this specific output layer, everything works as usual, especially the gradient of the mse loss function can travel backwards using backpropagation to update the weights $\theta$, $\alpha$ and $\beta$. The resulting architecture outperforms double DQN with prioritized replay on most Atari games, particularly games with repetitive actions.


## Distributed DQN (GORILA)

The main limitation of deep RL is the slowness of learning, which is mainly influenced by two factors:

* the *sample complexity*, i.e. the number of transitions needed to learn a satisfying policy.
* the online interaction with the environment.

The second factor is particularly critical in real-world applications like robotics: physical robots evolve in real time, so the acquisition speed of transitions will be limited. Even in simulation (video games, robot emulators), the simulator might turn out to be much slower than training the underlying neural network. Google Deepmind proposed the GORILA (General Reinforcement Learning Architecture) framework to speed up the training of DQN networks using distributed actors and learners [@Nair2015]. The framework is quite general and the distribution granularity can change depending on the task.

![GORILA architecture. Multiple actors interact with multiple copies of the environment and store their experiences in a (distributed) experience replay memory. Multiple DQN learners sample from the ERM and compute the gradient of the loss function w.r.t the parameters $\theta$. A master network (parameter server, possibly distributed) gathers the gradients, apply weight updates and synchronizes regularly both the actors and the learners with new parameters. Taken from @Nair2015.](img/gorila-global.png){#fig:gorila width=90%}

In GORILA, multiple actors interact with the environment to gather transitions. Each actor has an independent copy of the environment, so they can gather $N$ times more samples per second if there are $N$ actors. This is possible in simulation (starting $N$ instances of the same game in parallel) but much more complicated for real-world systems (but see @Gu2017 for an example where multiple identical robots are used to gather experiences in parallel).

The experienced transitions are sent as in DQN to an experience replay memory, which may be distributed or centralized. Multiple DQN learners will then sample a minibatch from the ERM and compute the DQN loss on this minibatch (also using a target network). All learners start with the same parameters $\theta$ and simply compute the gradient of the loss function $\frac{\partial \mathcal{L}(\theta)}{\partial \theta}$ on the minibatch. The gradients are sent to a parameter server (a master network) which uses the gradients to apply the optimizer (e.g. SGD) and find new values for the parameters $\theta$. Weight updates can also be applied in a distributed manner. This distributed method to train a network using multiple learners is now quite standard in deep learning: on multiple GPU systems, each GPU has a copy of the network and computes gradients on a different minibatch, while a master network integrates these gradients and updates the slaves.

The parameter server regularly updates the actors (to gather samples with the new policy) and the learners (to compute gradients w.r.t the new parameter values). Such a distributed system can greatly accelerate learning, but it can be quite tricky to find the optimum number of actors and learners (too many learners might degrade the stability) or their update rate (if the learners are not updated frequently enough, the gradients might not be correct). A similar idea is at the core of the A3C algorithm (@sec:asynchronous-advantage-actor-critic-a3c).

## Deep Recurrent Q-learning (DRQN)

The Atari games used as a benchmark for value-based methods are **partially observable MDPs** (POMDP), i.e. a single frame does not contain enough information to predict what is going to happen next (e.g. the speed and direction of the ball on the screen is not known). In DQN, partial observability is solved by stacking four consecutive frames and using the resulting tensor as an input to the CNN. if this approach worked well for most Atari games, it has several limitations (as explained in <https://medium.com/emergent-future/simple-reinforcement-learning-with-tensorflow-part-6-partial-observability-and-deep-recurrent-q-68463e9aeefc>):

1. It increases the size of the experience replay memory, as four video frames have to be stored for each transition.
2. It solves only short-term dependencies (instantaneous speeds). If the partial observability has long-term dependencies (an object has been hidden a long time ago but now becomes useful), the input to the neural network will not have that information. This is the main explanation why the original DQN performed so poorly on games necessitating long-term planning like Montezuma's revenge.

Building on previous ideas from the Schmidhuber's group [@Bakker2001;@Wierstra2007], @Hausknecht2015 replaced one of the fully-connected layers of the DQN network by a LSTM layer (see @sec:recurrent-neural-networks) while using single frames as inputs. The resulting **deep recurrent q-learning** (DRQN) network became able to solve POMDPs thanks to the astonishing learning abilities of LSTMs: the LSTM layer learn to remember which part of the sensory information will be useful to take decisions later.

However, LSTMs are not a magical solution either. They are trained using *truncated BPTT*, i.e. on a limited history of states. Long-term dependencies exceeding the truncation horizon cannot be learned. Additionally, all states in that horizon (i.e. all frames) have to be stored in the ERM to train the network, increasing drastically its size. Despite these limitations, DRQN is a much more elegant solution to the partial observability problem, letting the network decide which horizon it needs to solve long-term dependencies.

## Other variants of DQN

Double duelling DQN with prioritized replay is currently the state-of-the-art method for value-based deep RL (see @Hessel2017 for an experimental study of the contribution of each mechanism). Several minor to significant improvements have been proposed since the corresponding milestone papers. This section provides some short explanations and links to the original papers (to be organized and extended).

**Average-DQN** proposes to increase the stability and performance of DQN by replacing the single target network (a copy of the trained network) by an average of the last parameter values, in other words an average of many past target networks [@Anschel2016].

@He2016 proposed **fast reward propagation** thourgh optimality tightening to speedup learning: when rewards are sparse, they require a lot of episodes to propagate these rare rewards to all actions leading to it. Their method combines immediate rewards (single steps) with actual returns (as in Monte-Carlo) via a constrained optimization approach.

All RL methods based on the Bellman equations use the expectation operator to average returns and compute values. @Bellemare2017 propose to learn instead the **value distribution** through a modification of the Bellman equation. They show that learning the distribution of rewards rather than their mean leads to performance improvements. See <https://deepmind.com/blog/going-beyond-average-reinforcement-learning/> for more explanations.




<!--PAGEBREAK-->

# Policy Gradient methods

*Policy gradient* methods directly learn to estimate the policy $\pi_\theta$ with a parameterized function estimator. The goal of the neural network is to maximize an objective function representing the *return* (sum of rewards, noted $R(\tau)$ for simplicity) of the trajectories $\tau = (s_0, a_0, s_1, a_1, \ldots, s_T, a_T)$ selected by the policy $\pi_\theta$:

$$
    J(\theta) = {E}_{\tau \sim \rho_\theta}[R(\tau)] = {E}_{\tau \sim \rho_\theta}[\sum_{t=0}^T \gamma^t \, r(s_t, a_t, s_{t+1}) ]
$$

To maximize this objective function, the policy $\pi_\theta$ should only generate trajectories $\tau$ associated with high expected returns $R(\tau)$ and avoid those with low expected return, which is exactly what we want.

The objective function uses the mathematical expectation of the expected return over all possible trajectories. The likelihood that a trajectory is generated by the policy $\pi_\theta$ is noted $\rho_\theta(\tau)$ and given by:

$$
    \rho_\theta(\tau) = p_\theta(s_0, a_0, \ldots, s_T, a_T) = p_0 (s_0) \, \prod_{t=0}^T \pi_\theta(s_t, a_t) p(s_{t+1} | s_t, a_t)
$${#eq:likelihood_trajectory}

$p_0 (s_0)$ is the initial probability of starting in $s_0$ (independent from the policy) and $p(s_{t+1} | s_t, a_t)$ is the transition probability defining the MDP. Having the probability distribution of the trajectories, we can expand the mathematical expectation in the objective function:

$$
    J(\theta) = \int_\tau \rho_\theta (\tau) \, R(\tau) \, d\tau
$$

Monte-Carlo sampling could be used to estimate the objective function. One basically would have to sample multiple trajectories $\{\tau_i\}$ and average the obtained returns:

$$
    J(\theta) \approx \frac{1}{N} \, \sum_i \rho_\theta(\tau_i) \, R(\tau_i)
$$

However, this approach would suffer from several problems:

1. The trajectory space is extremely huge, so one would need a lot of sampled trajectories to have a correct estimate of the objective function.
2. For stability reasons, only small changes can be made to the policy at each iteration, so it would necessitate a lot of episodes (**sample complexity**).
3. The probability of a trajectory is difficult to estimate: the initial probability distribution $p_0$ has to be known, as well as the dynamics of the MDP ($p(s_{t+1} | s_t, a_t)$). Those could be approximated or learned (*model-based RL*), but it would limit the applicability of the method and approximation errors would accumulate quickly over a trajectory.
4. For continuing tasks ($T = \infty$), the return can not be estimated.

The methods presented in this section are called **policy gradient methods**. As we are going to apply gradient ascent on the weights $\theta$ in order to maximize $J(\theta)$, all we actually need is the gradient $\nabla_\theta J(\theta)$ of the objective function w.r.t the weights:

$$
    \nabla_\theta J(\theta) = \frac{\partial J(\theta)}{\partial \theta}
$$

Once a suitable estimation of this **policy gradient** is obtained, gradient ascent is straightforward:

$$
    \theta \leftarrow \theta + \eta \, \nabla_\theta J(\theta)
$$

The rest of this section basically presents methods allowing to estimate the policy gradient (REINFORCE, DPG) and to improve the sample complexity. See
<http://www.scholarpedia.org/article/Policy_gradient_methods> for an more detailed overview of policy gradient methods, and <http://karpathy.github.io/2016/05/31/rl/> for an excellent tutorial from Andrej Karpathy. The article of @Peters2008 is also a good overview of policy gradient methods.

## REINFORCE

### Estimating the policy gradient

@Williams1992 proposed a useful estimate of the policy gradient. Considering that the expected return $R(\tau)$ of a trajectory does not depend on the parameters $\theta$, one can simplify the policy gradient in the following way:

$$
    \nabla_\theta J(\theta) = \nabla_\theta \int_\tau \rho_\theta (\tau) \, R(\tau) \, d\tau =  \int_\tau (\nabla_\theta \rho_\theta (\tau)) \, R(\tau) \, d\tau
$$

We now use the **log-trick**, a simple identity based on the fact that: 

$$
    \frac{d \log f(x)}{dx} = \frac{f'(x)}{f(x)}
$$

to rewrite the policy gradient of a single trajectory:

$$
    \nabla_\theta \rho_\theta (\tau) = \rho_\theta (\tau) \, \nabla_\theta \log \rho_\theta (\tau)
$$

The policy gradient becomes:

$$
    \nabla_\theta J(\theta) =  \int_\tau \rho_\theta (\tau) \, \nabla_\theta \log \rho_\theta (\tau) \, R(\tau) \, d\tau
$$

which now has the form of a mathematical expectation:

$$
    \nabla_\theta J(\theta) =  {E}_{\tau \sim \rho_\theta}[ \nabla_\theta \log \rho_\theta (\tau) \, R(\tau) ]
$$

This means that we can obtain an estimate of the policy gradient by simply sampling different trajectories $\{\tau_i\}$ and averaging $\nabla_\theta \log \rho_\theta (\tau_i) \, R(\tau_i)$ (Monte-Carlo sampling).

Let's now look further at how the gradient of the log-likelihood of a trajectory $\log \pi_\theta (\tau)$ look like. Through its definition (@eq:likelihood_trajectory), the log-likelihood of a trajectory is:

$$
    \log \rho_\theta(\tau) = \log p_0 (s_0) + \sum_{t=0}^T \log \pi_\theta(s_t, a_t) + \sum_{t=0}^T \log p(s_{t+1} | s_t, a_t)
$${#eq:loglikelihood_trajectory}

$\log p_0 (s_0)$ and $\log p(s_{t+1} | s_t, a_t)$ do not depend on the parameters $\theta$ (they are defined by the MDP), so the gradient of the log-likelihood is simply:

$$
    \nabla_\theta \log \rho_\theta(\tau) = \sum_{t=0}^T \nabla_\theta \log \pi_\theta(s_t, a_t)
$${#eq:gradloglikelihood_trajectory}

$\nabla_\theta \log \pi_\theta(s_t, a_t)$ is called the **score function**.

This is the main reason why policy gradient algorithms are used: the gradient is independent from the MDP dynamics, allowing **model-free** learning. The policy gradient is then given by:

$$
    \nabla_\theta J(\theta) =  {E}_{\tau \sim \rho_\theta}[\sum_{t=0}^T \nabla_\theta \log \pi_\theta(s_t, a_t) \, R(\tau) ] =  {E}_{\tau \sim \rho_\theta}[ \sum_{t=0}^T \nabla_\theta \log \pi_\theta(s_t, a_t) \, (\sum_{t=0}^T \gamma^t r_{t+1})]
$$

Estimating the policy gradient now becomes straightforward using Monte-Carlo sampling. The resulting algorithm is called the **REINFORCE** algorithm [@Williams1992]:

---

* while not converged:

    * Sample $N$ trajectories $\{\tau_i\}$ using the current policy $\pi_\theta$ and observe the returns $\{R(\tau_i)\}$.
    * Estimate the policy gradient as an average over the trajectories:
    $$
       \nabla_\theta J(\theta) \approx \frac{1}{N} \sum_{i=1}^N \sum_{t=0}^T \nabla_\theta \log \pi_\theta(s_t, a_t) \, R(\tau_i)
    $$
    * Update the policy using gradient ascent:
    $$
        \theta \leftarrow \theta + \eta \, \nabla_\theta J(\theta)
    $$

---

While very simple, the REINFORCE algorithm does not work very well in practice:

1. The returns $\{R(\tau_i)\}$ have a very high variance (as the Q-values in value-based methods), which is problematic for NNs (see @sec:reducing-the-variance).
2. It requires a lot of episodes to converge (sample inefficient).
3. It only works with **online** learning: trajectories must be frequently sampled and immediately used to update the policy.  
4. The problem must be episodic ($T$ finite).

However, it has two main advantages:

1. It is a **model-free** method, i.e. one does not need to know anything about the MDP.
2. It also works on **partially observable** problems (POMDP): as the return is computed over complete trajectories, it does not matter if the states are not Markovian.

The methods presented in this section basically try to solve the limitations of REINFORCE (high variance, sample efficiency, online learning) to produce efficient policy gradient algorithms.

### Reducing the variance

The main problem with the REINFORCE algorithm is the **high variance** of the policy gradient. This variance comes from the fact that we learn stochastic policies (it is often unlikely to generate twice the exact same trajectory) in stochastic environments (rewards are stochastic, the same action in the same state may receive). Two trajectories which are identical at the beginning will be associated with different returns depending on the stochasticity of the policy, the transition probabilities and the probabilistic rewards.

Consider playing a game like chess with always the same opening, and then following a random policy. You may end up winning ($R=1$) or losing ($R=-1$) with some probability. The initial actions of the opening will receive a policy gradient which is sometimes positive, sometimes negative: were these actions good or bad? Should they be reinforced? In supervised learning, this would mean that the same image of a cat will be randomly associated to the labels "cat" or "dog" during training: the NN will not like it.

In supervised learning, there is no problem of variance in the outputs, as training sets are fixed. This is in contrary very hard to ensure in deep RL and constitutes one of its main limitations. The only direct solution is to sample enough trajectories and hope that the average will be able to smooth the variance. The problem is even worse in the following conditions:

* High-dimensional action spaces: it becomes difficult to sample the environment densely enough if many actions are possible.
* Long horizons: the longer the trajectory, the more likely it will be unique.
* Finite samples: if we cannot sample enough trajectories, the high variance can introduce a bias in the gradient, leading to poor convergence.

See <https://medium.com/mlreview/making-sense-of-the-bias-variance-trade-off-in-deep-reinforcement-learning-79cf1e83d565> for a nice explanation of the bias/variance trade-off in deep RL.

Another related problem is that the REINFORCE gradient is sensitive to **reward scaling**. Let's consider a simple MDP where only two trajectories $\tau_1$ and $\tau_2$ are possible. Depending on the choice of the reward function, the returns may be different:

1. $R(\tau_1) = 1$ and $R(\tau_2) = -1$
2. $R(\tau_1) = 3$ and $R(\tau_2) = 1$

In both cases, the policy should select the trajectory $\tau_1$. However, the policy gradient for $\tau_2$ will change its sign between the two cases, although the problem is the same! What we want to do is to maximize the returns, regardless the absolute value of the rewards, but the returns are unbounded. Because of the non-stationarity of the problem (the agent becomes better with training, so the returns of the sampled trajectories will increase), the policy gradients will increase over time, what is linked to the variance problem. Value-based methods addressed this problem by using **target networks**, but it is not a perfect solution (the gradients become biased). 


A first simple but effective idea to solve both problems would be to substract the mean of the sampled returns from the returns:

---

* while not converged:

    * Sample $N$ trajectories $\{\tau_i\}$ using the current policy $\pi_\theta$ and observe the returns $\{R(\tau_i)\}$.
    * Compute the mean return:
    $$
        \hat{R} = \frac{1}{N} \sum_{i=1}^N R(\tau_i)
    $$
    * Estimate the policy gradient as an average over the trajectories:
    $$
       \nabla_\theta J(\theta) \approx \frac{1}{N} \sum_{i=1}^N \sum_{t=0}^T \nabla_\theta \log \pi_\theta(s_t, a_t) \, ( R(\tau_i) - \hat{R})
    $$
    * Update the policy using gradient ascent:
    $$
        \theta \leftarrow \theta + \eta \, \nabla_\theta J(\theta)
    $$

---

This obviously solves the reward scaling problem, and reduces the variance of the gradients. But are we allowed to do this (i.e. does it introduce a bias to the gradient)? @Williams1992 showed that substracting a constant $b$ from the returns still leads to an unbiased estimate of the gradient:


$$
    \nabla_\theta J(\theta) =  {E}_{\tau \sim \rho_\theta}[\nabla_\theta \log \rho_\theta (\tau) \, (R(\tau) -b) ]
$$

The proof is actually quite simple:

$$
    {E}_{\tau \sim \rho_\theta}[\nabla_\theta \log \rho_\theta (\tau) \, b ] = \int_\tau \rho_\theta (\tau) \nabla_\theta \log \rho_\theta (\tau) \, b \, d\tau = \int_\tau \nabla_\theta  \rho_\theta (\tau) \, b \, d\tau = b \, \nabla_\theta \int_\tau \rho_\theta (\tau) \, d\tau =  b \, \nabla_\theta 1 = 0
$$

As long as the constant $b$ does not depend on $\theta$, the estimator is unbiased. The resulting algorithm is called **REINFORCE with baseline**. @Williams1992 has actually showed that the best baseline (the one which also reduces the variance) is the mean return weighted by the square of the gradient of the log-likelihood:

$$
    b = \frac{{E}_{\tau \sim \rho_\theta}[(\nabla_\theta \log \rho_\theta (\tau))^2 \, R(\tau)]}{{E}_{\tau \sim \rho_\theta}[(\nabla_\theta \log \rho_\theta (\tau))^2]}
$$

but the mean reward actually work quite well. Advantage actor-critic methods (@sec:advantage-actor-critic-methods) replace the constant $b$ with an estimate of the value of each state $\hat{V}(s_t)$. 

### Policy Gradient theorem

Let's have another look at the REINFORCE estimate of the policy gradient after sampling:

$$
   \nabla_\theta J(\theta) \approx \frac{1}{N} \sum_{i=1}^N \sum_{t=0}^T \nabla_\theta \log \pi_\theta(s_t, a_t) \, R(\tau_i) = \frac{1}{N} \sum_{i=1}^N (\sum_{t=0}^T \nabla_\theta \log \pi_\theta(s_t, a_t) ) \, (\sum_{t'=0}^T \gamma^{t'} \, r(s_{t'}, a_{t'}, s_{t'+1}) )
$$

For each transition $(s_t, a_t)$, the  gradient of its log-likelihood (*score function*) $\nabla_\theta \log \pi_\theta(s_t, a_t) )$ is multiplied by the return of the whole episode $R(\tau) = \sum_{t'=0}^T \gamma^{t'} \, r(s_{t'}, a_{t'}, s_{t'+1})$. However, the **causality principle** dictates that the reward received at $t=0$ does not depend on actions taken in the future, so we can simplify the return for each transition:

$$
 \nabla_\theta J(\theta) \approx \frac{1}{N} \sum_{i=1}^N (\sum_{t=0}^T \nabla_\theta \log \pi_\theta(s_t, a_t)  \, \sum_{t'=t}^T \gamma^{t'-t} \, r(s_{t'}, a_{t'}, s_{t'+1}) )
$$

The quantity $\hat{Q}(s_t, a_t) = \sum_{t'=t}^T \gamma^{t'-t} \, r(s_{t'}, a_{t'}, s_{t'+1})$ is called the **reward to-go** from the transition $(s_t, a_t)$, i.e. the discounted sum of future rewards after that transition. Quite obviously, the Q-value of that action is the mathematical expectation of this reward to-go. 

![The reward to-go is the sum of rewards gathered during a single trajectory after a transition $(s, a)$. The Q-value of the action $(s, a)$ is the expectation of the reward to-go. Taken from S. Levine's lecture <http://rll.berkeley.edu/deeprlcourse/>.](img/rewardtogo.png){#fig:rewardtogo width=30%}

$$
 \nabla_\theta J(\theta) \approx \frac{1}{N} \sum_{i=1}^N \sum_{t=0}^T \nabla_\theta \log \pi_\theta(s_t, a_t) \, \hat{Q}(s_t, a_t)
$$

@Sutton1999 showed that the policy gradient can be estimated by replacing the return of the sampled trajectory with the Q-value of each action, what leads to the **policy gradient theorem** (@eq:policygradienttheorem):

$$
    \nabla_\theta J(\theta) =  {E}_{s \sim \rho^\pi, a \sim \pi_\theta}[\nabla_\theta \log \pi_\theta(s, a) \, Q^{\pi_\theta}(s, a)]
$${#eq:policygradienttheorem}

where $\rho^\pi$ is the distribution of states reachable under the policy $\pi_\theta$. One clearly sees that REINFORCE is actually a special case of the policy gradient theorem, where the Q-value of an action is replaced by the return obtained during the corresponding trajectory. 

The problem is of course that the true Q-value of the actions is as unknown as the policy. However, @Sutton1999 showed that it is possible to estimate the Q-values with a function approximator $Q_\varphi(s, a)$ with parameters $\varphi$ and obtain an unbiased estimation:

$$
    \nabla_\theta J(\theta) =  {E}_{s \sim \rho^\pi, a \sim \pi_\theta}[\nabla_\theta \log \pi_\theta(s, a) \, Q_\varphi(s, a))]
$${#eq:policygradienttheoremapprox}

Formally, the Q-value approximator must respect the Compatible Function Approximation Theorem, which states that the value approximator must be compatible with the policy ($\nabla_\varphi Q_\varphi(s, a) = \nabla_\theta \log \pi_\theta(s, a)$) and minimize the mean-square error with the true Q-values ${E}_{s \sim \rho^\pi, a \sim \pi_\theta} [(Q^{\pi_\theta}(s, a) - Q_\varphi(s, a))^2]$. In the algorithms presented in this section, these conditions are either met or neglected.

The resulting algorithm belongs to the **actor-critic** class, in the sense that:

* The **actor** $\pi_\theta(s, a)$ learns to approximate the policy by maximizing @eq:policygradienttheoremapprox.
* The **critic** $Q_\varphi(s, a)$ learns to estimate the policy by minimizing the mse with the true Q-values.

@fig:actorcriticpolicy shows the architecture of the algorithm. The only problem left is to provide the critic with the true Q-values.

![Architecture of the policy gradient (PG) method.](img/policygradient.png){#fig:actorcriticpolicy width=65%}

Most policy-gradient algorithms (A3C, DPPG, TRPO) are actor-critic architectures. Some remarks:

* Trajectories now appear only implicitely in the policy gradient, one could even sample single transitions. It should therefore be possible (with modifications) to do **off-policy learning**, for example with a replay buffer of stored transitions as in DQN, or using importance sampling (@sec:importance-sampling). REINFORCE strictly works online.
* The policy gradient theorem suffers from the same **high variance** problem as REINFORCE. The different algorithms presented later are principally attempts to solve this problem and reduce the sample complexity: advantages, deterministic policies, natural gradients...
* The actor and the critic can be completely separated, or share some parameters.



<!--PAGEBREAK-->

## Advantage Actor-Critic methods

The *policy gradient theorem* provides an actor-critic architecture able to learn parameterized policies. In comparison to REINFORCE, the policy gradient depends on the Q-values of the actions taken during the trajectory rather than on the obtained returns $R(\tau)$. Quite obviously, it will also suffer from the high variance of the gradient (@sec:reducing-the-variance), requiring the use of baselines. In this section, the baseline is state-dependent and chosen equal to the value of the state $V^\pi(s)$, so the factor multiplying the log-likelihood of the policy is:

$$
    A^{\pi}(s, a) = Q^{\pi}(s, a) - V^\pi(s)
$$

which is the **advantage** of the action $a$ in $s$, as already seen in *duelling networks* (@sec:duelling-network). 

Now the problem is that the critic would have to approximate two functions: $Q^{\pi}(s, a)$ and $V^{\pi}(s)$. **Advantage actor-critic** methods presented in this section (A2C, A3C, GAE) approximate the advantage of an action:

$$
    \nabla_\theta J(\theta) =  {E}_{s \sim \rho^\pi, a \sim \pi_\theta}[\nabla_\theta \log \pi_\theta(s, a) \, A_\varphi(s, a)] 
$$


$A_\varphi(s, a)$ is called the **advantage estimate** and should be equal to the real advantage *in expectation*. 

Different methods could be used to compute the advantage estimate:

* $A_\varphi(s, a) =  R(s, a) - V_\varphi(s)$ is the **MC advantage estimate**, the Q-value of the action being replaced by the actual return.

* $A_\varphi(s, a) =   r(s, a, s') + \gamma \, V_\varphi(s') - V_\varphi(s))$ is the **TD advantage estimate** or TD error.

* $A_\varphi(s, a) =   \sum_{k=0}^{n-1} \gamma^{k} \, r_{t+k+1} + \gamma^n \, V_\varphi(s_{t+n+1}) - V_\varphi(s_t)$ is the **n-steps advantage estimate**. 


The most popular approach is the n-steps advantage, which is at the core of the methods A2C and A3C, and can be understood as a trade-off between MC and TD. MC and TD advantages could be used as well, but come with the respective disadvantages of MC (need for finite episodes, slow updates) and TD (unstable). Generalized Advantage Estimation (GAE, @sec:generalized-advantage-estimation-gae) takes another interesting approach to estimate the advantage. 

*Note:* A2C is actually derived from the A3C algorithm presented later, but it is simpler to explain it first. See <https://blog.openai.com/baselines-acktr-a2c/> for an explanation of the reasons. A good explanation of A2C and A3C with Python code is available at <https://cgnicholls.github.io/reinforcement-learning/2017/03/27/a3c.html>.

### Advantage Actor-Critic (A2C)

The first aspect of A2C is that it relies on n-steps updating, which is a trade-off between MC and TD: 

* MC waits until the end of an episode to update the value of an action using the reward to-go (sum of obtained rewards) $R(s, a)$.
* TD updates immediately the action using the immediate reward $r(s, a, s')$ and approximates the rest with the value of the next state $V^\pi(s)$.
* n-steps uses the $n$ next immediate rewards and approximates the rest with the value of the state visited $n$ steps later.


$$
    \nabla_\theta J(\theta) =  {E}_{s_t \sim \rho^\pi, a_t \sim \pi_\theta}[\nabla_\theta \log \pi_\theta(s_t, a_t) \, ( \sum_{k=0}^{n-1} \gamma^{k} \, r_{t+k+1} + \gamma^n \, V_\varphi(s_{t+n+1}) - V_\varphi(s_t))] 
$${#eq:a2c}

TD can be therefore be seen as a 1-step algorithm. For sparse rewards (mostly zero, +1 or -1 at the end of a game for example), this allows to update the $n$ last actions which lead to a win/loss, instead of only the last one in TD, speeding up learning. However, there is no need for finite episodes as in MC. In other words, n-steps estimation ensures a trade-off between bias (wrong upadtes based on estimated as in TD) and variance (variability of the obtained returns as in MC). An alternative to n-steps updating is *eligibility traces* [@Sutton1998].

Having a computable formula for the policy gradient, the algorithm is rather simple:

1. Acquire a batch of transitions $(s, a, r, s')$ using the current policy $\pi_\theta$ (either a finite episode or a truncated one).
2. For each state encountered, compute the discounted sum of the next $n$ rewards $\sum_{k=0}^{n} \gamma^{k} \, r_{t+k+1}$ and use the critic to estimate the value of the state encountered $n$ steps later $V_\varphi(s_{t+n+1})$.
3. Update the actor using @eq:a2c.
4. Update the critic to minimize the TD error between the estimated value of a state and its true value.
5. Repeat.

This is not very different in essence from REINFORCE (sample transitions, compute the return, update the policy), apart from the facts that episodes do not need to be finite and that a critic has to be learned in parallel. A more detailed pseudo-algorithm for a single A2C learner is the following:

---

* Initialize the actor $\pi_\theta$ and the critic $V_\varphi$ with random weights.
* Observe the initial state $s_0$.
* for $t \in [0, T_\text{total}]$:
    * Initialize empty minibatch.
    * for $k \in [0, n]$: # Sample episode
        * Select a action $a_k$ using the actor $\pi_\theta$.
        * Perform the action $a_k$ and observe the next state $s_{k+1}$ and the reward $r_{k+1}$.
        * Store $(s_k, a_k, r_{k+1})$ in the minibatch.
    * if $s_k$ is not terminal: set $R = V_\varphi(s_k)$ with the critic, else $R=0$.
    
    * Reset gradient $d\theta$ and $d\varphi$ to 0.
    * for $k \in [n, 0]$: # Backwards iteration over the episode
        * Update the discounted sum of rewards $R = r_k + \gamma \, R$
        * Accumulate the policy gradient using the critic:
        $$
            d\theta \leftarrow d\theta + \nabla_\theta \log \pi_\theta(s_k, a_k) \, (R - V_\varphi(s_k))
        $$
        * Accumulate the critic gradient:
        $$
            d\varphi \leftarrow d\varphi + \nabla_\varphi (R - V_\varphi(s_k))^2
        $$
    
    * Update the actor and the critic with the accumulated gradients using gradient descent or similar:
    $$
        \theta \leftarrow \theta + \eta \, d\theta \qquad \varphi \leftarrow \varphi + \eta \, d\varphi
    $$

---

Note that not all states are updated with the same horizon $n$: the last action encountered in the sampled episode will only use the last reward and the value of the final state (TD learning), while the very first action will use the $n$ accumulated rewards. In practice it does not really matter, but the choice of the discount rate $\gamma$ will have a significant influence on the results.

As many actor-critic methods, A2C performs online learning: a couple of transitions are explored using the current policy, which is immediately updated. As for value-based networks (e.g. DQN, @sec:deep-q-network-dqn), the underlying NN will be affected by the correlated inputs and outputs: a single batch contains similar states and action (e.g. consecutive frames of a video game). The solution retained in A2C and A3C does not depend on an *experience replay memory* as DQN, but rather on the use of **multiple parallel actors and learners**.

The idea is depicted on @fig:a3carchi (actually for A3C, but works with A2C). The actor and critic are stored in a global network. Multiple instances of the environment are created in different parallel threads (the **workers** or **actor-learners**). At the beginning of an episode, each worker receives a copy of the actor and critic weights from the global network. Each worker samples an episode (starting from different initial states, so the episodes are uncorrelated), computes the accumulated gradients and sends them back to the global network. The global networks merges the gradients and uses them to update the parameters of the policy and critic networks. The new parameters are send to each worker again, until it converges.

---

* Initialize the actor $\pi_\theta$ and the critic $V_\varphi$ in the global network.
* repeat:
    * for each worker $i$ in **parallel**:
        * Get a copy of the global actor $\pi_\theta$ and critic $V_\varphi$.
        * Sample an episode of $n$ steps.
        * Return the accumulated gradients $d\theta_i$ and $d\varphi_i$.
    * Wait for all workers to terminate.
    * Merge all accumulated gradients into $d\theta$ and $d\varphi$.
    * Update the global actor and critic networks.

---

This solves the problem of correlated inputs and outputs, as each worker explores different regions of the environment (one can set different initial states in each worker, vary the exploration rate, etc), so the final batch of transitions used for training the global networks is much less correlated. The only drawback of this approach is that it has to be possible to explore multiple environments in parallel. This is easy to achieve in simulated environments (e.g. video games) but much harder in real-world systems like robots. A brute-force solution for robotics is simply to buy enough robots and let them learn in parallel [@Gu2017].


### Asynchronous Advantage Actor-Critic (A3C)

![Architecture of A3C. A master network interacts asynchronously with several workers, each having a copy of the network and interacting with a separate environment. At the end of an episode, the accumulated gradients are sent back to the master network, and a new value of the parameters is sent to the workers.  Taken from <https://medium.com/emergent-future/simple-reinforcement-learning-with-tensorflow-part-8-asynchronous-actor-critic-agents-a3c-c88f72a5e9f2>.](img/A3C_architecture.png){#fig:a3carchi width=70%}

Asynchronous Advantage Actor-Critic [A3C,@Mnih2016] extends the approach of A2C by removing the need of synchronization between the workers at the end of each episode before applying the gradients. The rationale behind this is that each worker may need different times to complete its task, so they need to be synchronized. Some workers might then be idle most of the time, what is a waste of resources. Gradient merging and parameter updates are sequential operations, so no significant speedup is to be expected even if one increases the number of workers.

The solution retained in A3C is to simply skip the synchronization step: each worker reads and writes the network parameters whenever it wants. Without synchronization barriers, there is of course a risk that one worker tries to read the network parameters while another writes them: the obtained parameters would be a mix of two different networks. Surprisingly, it does not matter: if the learning rate is small enough, there is anyway not a big difference between two successive versions of the network parameters. This kind of "dirty" parameter sharing is called *HogWild!* updating [@Niu2011] and has been proven to work under certain conditions which are met here.

The resulting A3C pseudocode is summarized here:

---

* Initialize the actor $\pi_\theta$ and the critic $V_\varphi$ in the global network.

* for each worker $i$ in **parallel**:
    * repeat:
        * Get a copy of the global actor $\pi_\theta$ and critic $V_\varphi$.
        * Sample an episode of $n$ steps.
        * Compute the accumulated gradients $d\theta_i$ and $d\varphi_i$.
        * Update the global actor and critic networks asynchronously (HogWild!).

---

The workers are fully independent: their only communication is through the **asynchronous** updating of the global networks. This can lead to very efficient parallel implementations: in the original A3C paper [@Mnih2016], they solved the same Atari games than DQN using 16 CPU cores instead of a powerful GPU, while achieving a better performance in less training time (1 day instead of 8). The speedup is almost linear: the more workers, the faster the computations, the better the performance (as the policy updates are less correlated).

#### Entropy regularization {-}

An interesting addition in A3C is the way they enforce exploration during learning. In actor-critic methods, exploration classically relies on the fact that the learned policies are stochastic (**on-policy**): $\pi(s, a)$ describes the probability of taking the action $a$ in the state $s$. In discrete action spaces, the output of the actor is usually a softmax layer, ensuring that all actions get a non-zero probability of being selected during training. In continuous action spaces, the executed action is sampled from the output probability distribution. However, this is often not sufficient and hard to control.

In A3C, the authors added an **entropy regularization** term [@Williams1991] to the policy gradient update:

$$
    \nabla_\theta J(\theta) =  {E}_{s_t \sim \rho^\pi, a_t \sim \pi_\theta}[\nabla_\theta \log \pi_\theta(s_t, a_t) \, ( R_t - V_\varphi(s_t)) + \beta \, \nabla_\theta H(\pi_\theta(s_t))] 
$${#eq:a3c_entropy}

For discrete actions, the entropy of the policy for a state $s_t$ is simple to compute: $H(\pi_\theta(s_t)) = - \sum_a \pi_\theta(s_t, a) \, \log \pi_\theta(s_t, a)$. For continuous actions, replace the sum with an integral. It measures the "randomness" of the policy: if the policy is fully deterministic (the same action is systematically selected), the entropy is zero as it carries no information. If the policy is completely random, the entropy is maximal. Maximizing the entropy at the same time as the returns improves exploration by forcing the policy to be as non-deterministic as possible.

The parameter $\beta$ controls the level of regularization: we do not want the entropy to dominate either, as a purely random policy does not bring much reward. If $\beta$ is chosen too low, the entropy won't play a significant role in the optimization and we may obtain a suboptimal deterministic policy early during training as there was not enough exploration. If $\beta$ is too high, the policy will be random. Entropy regularization adds yet another hyperparameter to the problem, but can be really useful for convergence when adequately chosen.



#### Comparison between A3C and DQN {-}

1. DQN uses an experience replay memory to solve the correlation of inputs/outputs problem, while A3C uses parallel actor-learners. If multiple copies of the environment are available, A3C should be preferred because the ERM slows down learning (very old transitions are still used for learning) and requires a lot of memory.
2. A3C is on-policy: the learned policy must be used to explore the environment. DQN is off-policy: a behaviour policy can be used for exploration, allowing to guide externally which regions of the state-action space should be explored. Off-policy are often preferred when expert knowledge is available. 
3. DQN has to use target networks to fight the non-stationarity of the Q-values. A3C uses state-values and advantages, which are much more stable over time than Q-values, so there is no need for target networks.
4. A3C can deal with continuous action spaces easily, as it uses a parameterized policy. DQN has to be strongly modified to deal with this problem.
5. Both can deal with POMDP by using LSTMs in the actor network: A3C [@Mnih2016;@Mirowski2016], DQN [@Hausknecht2015, see @sec:deep-recurrent-q-learning-drqn].



### Generalized Advantage Estimation (GAE)

The different versions of the policy gradient seen so far take the form:

$$
    \nabla_\theta J(\theta) =  {E}_{s_t \sim \rho^\pi, a_t \sim \pi_\theta}[\nabla_\theta \log \pi_\theta (s_t, a_t) \, \psi_t ]
$$

where:

* $\psi_t = R_t$ is the *REINFORCE* algorithm (MC sampling).

* $\psi_t = R_t - b$ is the *REINFORCE with baseline* algorithm.

* $\psi_t = Q^\pi(s_t, a_t)$ is the *policy gradient theorem*.

* $\psi_t = A^\pi(s_t, a_t)$ is the *advantage actor critic*.

* $\psi_t = r_{t+1} + \gamma \, V^\pi(s_{t+1}) - V^\pi(s_t)$ is the *TD actor critic*.

* $\psi_t = \sum_{k=0}^{n-1} \gamma^{k} \, r_{t+k+1} + \gamma^n \, V^\pi(s_{t+n+1}) - V^\pi(s_t)$ is the *n-steps algorithm* (A2C).


Generally speaking:

* the more $\psi_t$ relies on real rewards (e.g. $R_t$), the more the gradient will be correct on average (small bias), but the more it will vary (high variance). This increases the sample complexity: we need to average more samples to correctly estimate the gradient.
* the more $\psi_t$ relies on estimations (e.g. the TD error), the more stable the gradient (small variance), but the more incorrect it is (high bias). This can lead to suboptimal policies, i.e. local optima of the objective function.

This is the classical bias/variance trade-off in machine learning (see @sec:reducing-the-variance). The n-steps algorithm used in A2C is an attempt to mitigate between these extrema. @Schulman2015b proposed the **Generalized Advantage Estimate** (GAE) to further control the bias/variance trade-off.

Let's define the n-steps advantage:

$$
    A^{n}_t = \sum_{k=0}^{n-1} \gamma^{k} \, r_{t+k+1} + \gamma^n \, V^\pi(s_{t+n+1}) - V^\pi(s_t)
$$

It is easy to show recursively that it depends on the TD error $\delta_t = r_{t+1} + \gamma \, V^\pi(s_{t+1}) - V^\pi(s_t)$ of the $n$ next steps:

$$
    A^{n}_t = \sum_{l=0}^{n-1} \gamma^l \, \delta_{t+l}
$$

In other words, the prediction error over $n$ steps is the (discounted) sum of the prediction errors between two successive steps. Now, what is the optimal value of $n$? GAE decides not to choose and to simply average all n-steps advantages and to weight them with a discount parameter $\lambda$. This defines the **Generalized Advantage Estimator** $A^{\text{GAE}(\gamma, \lambda)}_t$:

$$
    A^{\text{GAE}(\gamma, \lambda)}_t = (1-\lambda) \, \sum_{l=0}^\infty \lambda^l A^l_t = \sum_{l=0}^\infty (\gamma \lambda)^l \delta_{t+l}
$$ 

The GAE is the discounted sum of all n-steps advantages. When $\lambda=0$, we have $A^{\text{GAE}(\gamma, 0)}_t = A^{0}_t = \delta_t$, i.e. the TD advantage (high bias, low variance). When $\lambda=1$, we have (at the limit) $A^{\text{GAE}(\gamma, 1)}_t = R_t$, i.e. the MC advantage (low bias, high variance). Choosing the right value of $\lambda$ between 0 and 1 allows to control the bias/variance trade-off.

$\gamma$ and $\lambda$ play different roles in GAE: $\gamma$ determines the scale or horizon of the value functions: how much future rewards rewards are to be taken into account. The higher $\gamma <1$, the smaller the bias, but the higher the variance. Empirically, @Schulman2015b found that small $\lambda$ values introduce less bias than $\gamma$, so $\lambda$ can be chosen smaller than $\gamma$ (which is typically 0.99).

The policy gradient for Generalized Advantage Estimation is therefore:

$$
    \nabla_\theta J(\theta) =  {E}_{s_t \sim \rho^\pi, a_t \sim \pi_\theta}[\nabla_\theta \log \pi_\theta (s_t, a_t) \, \sum_{l=0}^\infty (\gamma \lambda)^l \delta_{t+l} ]
$$

Note that @Schulman2015b additionally use *trust region optimization* to stabilize learning and further reduce the bias (see @sec:trust-region-policy-optimization-trpo), for now just consider it is a better optimization method than  gradient descent. The GAE algorithm is summarized here:

---

* Initialize the actor $\pi_\theta$ and the critic $V_\varphi$ with random weights.
* for $t \in [0, T_\text{total}]$:
    * Initialize empty minibatch.
    * for $k \in [0, n]$:
        * Select a action $a_k$ using the actor $\pi_\theta$.
        * Perform the action $a_k$ and observe the next state $s_{k+1}$ and the reward $r_{k+1}$.
        * Store $(s_k, a_k, r_{k+1})$ in the minibatch.
    
    * for $k \in [0, n]$:
        * Compute the TD error $\delta_k = r_{k+1} + \gamma \, V_\varphi(s_{k+1}) - V_\varphi(s_k)$
        
    * for $k \in [0, n]$:
        * Compute the GAE advantage $A^{\text{GAE}(\gamma, \lambda)}_k = \sum_{l=0}^\infty (\gamma \lambda)^l \delta_{k+l}$
        
    * Update the actor using the GAE advantage and natural gradients (TRPO).

    * Update the critic using natural gradients (TRPO)

---

### Stochastic actor-critic for continuous action spaces

The actor-critic method presented above use **stochastic policies** $\pi_\theta(s, a)$ assigning parameterized probabilities of being selecting to each $(s, a)$ pair. 

* When the action space is discrete, the output layer of the actor is simply a *softmax* layer with as many neurons as possible actions in each state, making sure the probabilities sum to one. It is then straightforward to sample an action from this layer.

* When the action space is continuous (e.g. the different joints of a robotic arm), one has to make an assumption on the underlying distribution. The actor learns the parameters of the distribution (for example the mean and variance of a Gaussian distribution) and the executed action is simply sampled from the parameterized distribution.

The most used distribution is the Gaussian distribution, leading to **Gaussian policies**. In this case, the output of the actor is a mean vector $\mu_\theta(s)$ and possibly a variance vector $\sigma_\theta(s)$. The policy is then simply defined as:

$$
    \pi_\theta(s, a) = \frac{1}{\sqrt{2\pi\sigma_\theta(s)}} \, \exp -\frac{(a - \mu_\theta(s))^2}{2\sigma_\theta(s)^2}
$$

In order to use backpropagation on the policy gradient (i.e. getting an analytical form of the score function $\nabla_\theta \log \pi_\theta (s, a)$), one can use the *re-parameterization trick* [@Heess2015] by rewriting the policy as:

$$
    a = \mu_\theta(s) + \sigma_\theta(s) \times \xi \qquad \text{where} \qquad \xi \sim \mathcal{N}(0,1)
$$

To select an action, we only need to sample $\xi$ from the unit normal distribution, multiply it by the standard deviation and add the mean. To compute the score function, we use the following partial derivatives:

$$
    \nabla_\mu \log \pi_\theta (s, a) = \frac{a - \mu_\theta(s)}{\sigma_\theta(s)^2} \qquad \nabla_\sigma \log \pi_\theta (s, a) = \frac{(a - \mu_\theta(s))^2}{\sigma_\theta(s)^3} - \frac{1}{\sigma_\theta(s)}
$$

and use the chain rule to obtain the score function. The *re-parameterization trick* is a cool trick to apply backpropagation on stochastic problems: it is for example used in the variational auto-encoders [VAR;@Kingma2013].

Depending on the problem, one could use: 1) a fixed $\sigma$ for the whole action space, 2) a fixed $\sigma$ per DoF, 3) a learnable $\sigma$ per DoF (assuming all action dimensions to be mutually independent) or even 4) a covariance matrix $\Sigma$ when the action dimensions are dependent.

One limitation of Gaussian policies is that their support is infinite: even with a small variance, samples actions can deviate a lot (albeit rarely) from the mean. This is particularly a problem when action must have a limited range: the torque of an effector, the linear or angular speed of a car, etc. Clipping the sampled action to minimal and maximal values introduces a bias which can impair learning. @Chou2017 proposed to use **beta-distributions** instead of Gaussian ones in the actor. Sampled values have a $[0,1]$ support, which can rescaled to $[v_\text{min},v_\text{max}]$ easily. They show that beta policies have less bias than Gaussian policies in most continuous problems.


<!--PAGEBREAK-->

## Deterministic Policy Gradient (DPG)

So far, the actor produces a stochastic policy $\pi_\theta(s)$ assigning probabilities to each discrete action or necessitating sampling in some distribution for continuous actions (see @sec:stochastic-actor-critic-for-continuous-action-spaces). The main advantage is that stochastic policies ensure **exploration** of the state-action space: as most actions have a non-zero probability of being selected, we should not miss any important reward which should be ignored if the greedy action is always selected (exploration/exploitation dilemma). There are however two drawbacks:

1. The policy gradient theorem only works **on-policy**: the value of an action estimated by the critic must have been produced recently by the actor, otherwise the bias would increases dramatically. This prevents the use of experience replay memory as in DQN to stabilize learning. 
2. Because of the stochasticity of the policy, the returns may vary considerably between two episodes generated by the same optimal policy. This induces a lot of **variance** in the policy gradient, which explains why policy gradient methods have a worse **sample complexity** than value-based methods: they need more samples to get rid of this variance. 

Successful value-based methods such as DQN produce a **deterministic policy**, where the action to be executed after learning is simply the greedy action $a^*_t = \text{argmax}_a Q_\theta(s_t, a)$. Exploration is enforced by forcing the behaviour policy (the one used to generate the sample) to be stochastic ($\epsilon$-greedy), but the learned policy is itself deterministic. This is called **off-policy** learning, allowing to use a different policy than the learned one to explore. When using an experience replay memory, the behaviour policy is simply an older version of the learning policy (as samples stored in the ERM were generated by an older version of the actor).

In this section, we will see the now state-of-the-art method DDPG (Deep Deterministic Policy Gradient), which tries to combine the advantages of policy gradient methods (continous or highly dimensional outputs, stability) with those of value-based methods (sample efficiency, off-policy). @sec:off-policy-actor-critic will present alternative to the deterministic policy methods to achieve off-policy learning.


### Deterministic policy gradient theorem

We now assume that we want to learn a parameterized **deterministic policy** $\mu_\theta(s)$. As for the stochastic policy gradient theorem, the goal is to maximize the expectation over all states reachable by the policy of the reward to-go (return) after each action:

$$
    J(\theta) =  {E}_{s \sim \rho^\mu}[R(s, \mu_\theta(s))]
$$

As in the stochastic case, the distribution of states reachable by the policy $\rho^\mu$ is impossible to estimate, so we will have to perform approximations. Building on @Hafner2011, @Silver2014 showed how to obtain a usable gradient for the objective function when the policy is deterministic.

Considering that the Q-value of an action is the expectation of the reward to-go after that action $Q^\pi(s, a) = E[R(s, a)]$, maximizing the returns or maximizing the true Q-value of all actions leads to the same optimal policy. This is the basic idea behind dynamic programming (see @sec:dynamic-programming). where *policy evaluation* first finds the true Q-value of all state-action pairs and *policy improvement* changes the policy by selecting the action with the maximal Q-value $a^*_t = \text{argmax}_a Q_\theta(s_t, a)$. 

In the continuous case, we will simply state that the gradient of the objective function is the same as the gradient of the Q-value. Supposing we have an unbiased estimate $Q^\mu(s, a)$ of the value of any action in $s$, changing the policy $\mu_\theta(s)$ in the direction of $\nabla_\theta Q^\mu(s, a)$ leads to an action with a higher Q-value, therefore with a higher associated return:

$$
    \nabla_\theta J(\theta) = {E}_{s \sim \rho^\mu}[\nabla_\theta Q^\mu(s, a) |_{a = \mu_\theta(s)}]
$$

This notation means that the gradient w.r.t $a$ of the Q-value is taken for $a = \mu_\theta(s)$. We now use the chain rule to expland the gradient of the Q-value:

$$
    \nabla_\theta J(\theta) = {E}_{s \sim \rho^\mu}[\nabla_\theta \mu_\theta(s) \times \nabla_a Q^\mu(s, a) |_{a = \mu_\theta(s)}]
$$

It is perhaps clearer using partial derivatives and simplifying the notations:

$$
    \frac{\partial Q(s,a)}{\partial \theta} = \frac{\partial Q(s,a)}{\partial a} \times \frac{\partial a}{\partial \theta}
$$

The first term defines of the Q-value of an action changes when one varies slightly the action (if I move my joint a bit more to the right, do I get a higher Q-value, hence more reward?), the second term defines how the action changes when the parameters $\theta$ of the actor change (which weights should be changed in order to produce that action with a silghtly higher Q-value?). 

We already see an **actor-critic** architecture emerging from this equation: $\nabla_\theta \mu_\theta(s)$ only depends on the parameterized actor, while $\nabla_a Q^\mu(s, a)$ is a sort of critic, telling the actor how to change its policy towards actions associated with more reward.

As in the stochastic policy gradient theorem, the question is now how to obtain an unbiased estimate of the Q-value of any action and compute its gradient. @Silver2014 showed that it is possible to use a function approximator $Q_\varphi(s, a)$ as long as it is compatible and minimize the quadratic error with the true Q-values:

$$
    \nabla_\theta J(\theta) = {E}_{s \sim \rho^\mu}[\nabla_\theta \mu_\theta(s) \times \nabla_a Q_\varphi(s, a) |_{a = \mu_\theta(s)}]
$$
$$
    J(\varphi) = {E}_{s \sim \rho^\mu}[(Q^\mu(s, \mu_\theta(s)) - Q_\varphi(s, \mu_\theta(s)))^2]
$$


@fig:dpg outlines the actor-critic architecture of the DPG (deterministic policy gradient) method, to compare with the actor-critic architecture of the stochastic policy gradient (@fig:actorcriticpolicy).


![Architecture of the DPG (deterministic policy gradient) method.](img/dpg.png){#fig:dpg width=65%}

@Silver2014 investigated the performance of DPG using linear function approximators and showed that it compared positively to stochastic algorithms in high-dimensional or continuous action spaces. However, non-linear function approximators such as deep NN would not work yet. 

### Deep Deterministic Policy Gradient (DDPG)

@Lillicrap2015 extended the DPG approach to work with non-linear function approximators. In fact, they combined ideas from DQN and DPG to create a very successful algorithm able to solve continuous problems off-policy, the **deep deterministic policy gradient** (DDPG) algorithm..

The key ideas borrowed from DQN are:

* Using an **experience replay memory** to store past transitions and learn off-policy.
* Using **target networks** to stabilize learning.

They modified the update frequency of the target networks originally used in DQN. In DQN, the target networks are updated with the parameters of the trained networks every couple of thousands of steps. The target networks therefore change a lot between two updates, but not very often. @Lillicrap2015 found that it is actually better to make the target networks slowly track the trained networks, by updating their parameters after each update of the trained network using a sliding mean for both the actor and the critic:

$$
    \theta' = \tau \, \theta + (1-\tau) \, \theta'
$$ 

with $\tau <<1$. Using this update rule, the target networks are always "late" with respect to the trained networks, providing more stability to the learning of Q-values. 

The key idea borrowed from DPG is the policy gradient for the actor. The critic is learned using regular Q-learning and target networks:

$$
    J(\varphi) = {E}_{s \sim \rho^\mu}[(r(s, a, s') + \gamma \, Q_{\varphi'}(s', \mu_{\theta'}(s')) - Q_\varphi(s, a))^2]
$$

One remaining issue is **exploration**: as the policy is deterministic, it can very quickly produce always the same actions, missing perhaps more rewarding options. Some environments are naturally noisy, enforcing exploration by itself, but this cannot be assumed in the general case. The solution retained in DDPG is an **additive noise** added to the deterministic action to explore the environment:

$$
    a_t = \mu_\theta(s_t) + \xi
$$

This additive noise could be anything, but the most practical choise is to use an **Ornstein-Uhlenbeck** process [@Ornstein1930] to generate temporally correlated noise with zero mean. Ornstein-Uhlenbeck processes are used in physics to model the velocity of Brownian particles with friction. It updates a variable $x_t$ using a stochastic differential equation (SDE):


$$ dx_t = \theta (\mu - x_t) dt + \sigma dW_t \qquad \text{with} \qquad dW_t = \mathcal{N}(0, dt)$$

$\mu$ is the mean of the process (usually 0), $\theta$ is the friction (how fast it varies with noise) and $\sigma$ controls the amount of noise. @fig:OU shows three independent runs of a Ornstein-Uhlenbeck process: successive values of the variable $x_t$ vary randomly but coherently over time.


![Three independent runs of an Ornstein-Uhlenbeck process with $\mu=0$, $\sigma=0.3$, $\theta=0.15$  and $dt=0.1$. The code is adapted from <https://gist.github.com/jimfleming/9a62b2f7ed047ff78e95b5398e955b9e>](img/OU.png){#fig:OU width=80%}

The architecture of the DDPG algorithm is depicted on @fig:ddpg.

![Architecture of the DDPG (deep deterministic policy gradient) algorithm.](img/ddpg.png){#fig:ddpg width=70%}

The pseudo-algorithm is as follows:


---

* Initialize actor network $\mu_{\theta}$ and critic $Q_\varphi$ with random weights.
* Create the target networks $\mu_{\theta'}$ and $Q_{\varphi'}$.
* Initialize experience replay memory $\mathcal{D}$ of maximal size $N$.

* for episode $\in [1, M]$:
    * Initialize random process $\xi$. 
    * Observe the initial state $s_0$.
    * for $t \in [0, T_\text{max}]$:
        * Select the action $a_t = \mu_\theta(s_t) + \xi$ according to the current policy and the noise.
        * Perform the action $a_t$ and observe the next state $s_{t+1}$ and the reward $r_{t+1}$.
        * Store $(s_t, a_t, r_{t+1}, s_{t+1})$ in the experience replay memory.
        
        * Sample a minibatch of $N$ transitions randomly from $\mathcal{D}$.
        * For each transition $(s_k, a_k, r_k, s'_k)$ in the minibatch:            
            * Compute the target value using target networks $y_k = r_k + \gamma \, Q_{\varphi'}(s'_k, \mu_{\theta'}(s'_k))$.
        * Update the critic by minimizing:
        $$
            \mathcal{L}(\varphi) = \frac{1}{N} \sum_k (y_k - Q_\varphi(s_k, a_k))^2
        $$
        * Update the actor using the sampled policy gradient:
        $$
            \nabla_\theta J(\theta) = \frac{1}{N} \sum_k \nabla_\theta \mu_\theta(s_k) \times \nabla_a Q_\varphi(s_k, a) |_{a = \mu_\theta(s_k)}
        $$
        * Update the target networks:  
        $$\theta' \leftarrow \tau \theta + (1-\tau) \, \theta'$$
        $$\varphi' \leftarrow \tau \varphi + (1-\tau) \, \varphi'$$

---

The question that arises is how to obtain the gradient of the Q-value w.r.t the action $\nabla_a Q_\varphi(s, a)$, when the critic only outputs the Q-value $Q_\varphi(s, a)$. Fortunately, deep neural networks are simulated using automatic differentiation libraries such as tensorflow, theano, pytorch and co, which can automatically output this gradient. If not available, one could simply use the finite difference method (Euler) to approximate this gradient. One has to evaluate the Q-value in $a +da$, where $da$ is a very small change of the executed action, and estimate the gradient using:

$$
    \nabla_a Q_\varphi(s, a) \approx \frac{Q_\varphi(s, a + da) - Q_\varphi(s, a)}{da}
$$ 

DDPG has rapidly become the state-of-the-art model-free method for continuous spaces (although now PPO is preferred). It is able to learn efficent policies on most contiuous problems, either pixel-based or using individual state variables. In the original DDPG paper, they showed that *batch normalization* [@Ioffe2015] is crucial in stabilizing the training of deep networks on such problems. Its main limitation is its high sample complexity. Distributed versions of DDPG have been proposed to speed up learning, similarly to the parallel actor learners of A3C [@Loetzsch2017;@Popov2017].

**Additional references:** see <http://pemami4911.github.io/blog/2016/08/21/ddpg-rl.html> for additional explanations and step-by-step tensorflow code.



<!--PAGEBREAK-->



## Natural Gradients

Natural policy gradient @Kakade2001

### Natural Actor Critic (NAC)

@Peters2008

### Trust Region Policy Optimization (TRPO)

@Schulman2015a

### Proximal Policy Optimization (PPO)

@Schulman2017

Explanations from OpenAI: <https://blog.openai.com/openai-baselines-ppo/#content>

## Off-policy Actor-Critic

### Importance sampling


@Meuleau200
@Tang2010
@Levine2013

### Linear Off-Policy Actor-Critic (OffPAC)

@Degris2012

### Actor-Critic with Experience Replay (ACER)

@Wang2017


## Other policy gradient methods


### Stochastic Value Gradient (SVG)

@Heess2015

### Fictitious Self-Play (FSP)

@Heinrich2015 @Heinrich2016

### Q-Prop

@Gu2016

### Normalized Advantage Function (NAF)

@Gu2016b

## Comparison between value-based and policy gradient methods

<https://flyyufelix.github.io/2017/10/12/dqn-vs-pg.html>

Advantages of policy gradient:

* Better convergence properties.
* Effective in high-dimensional or continuous action spaces.
* Can learn stochastic policies.

Disadvantages:

* Typically converge to a local rather than global optimum.
* Evaluating a policy is typically inefficient and high variance.

Policy gradient methods are therefore usually less sample efficient, but can be more stable than value-based methods (Duan et al., 2016).

## Gradient-free policy search

The policy gradient methods presented above rely on backpropagation and gradient descent/ascent to update the parameters of the policy and maximize the objective function. Gradient descent is generally slow, sample inefficient and subject to local minima, but is nevertheless the go-to method in neural networks. However, it is not the only optimization that can be used in deep RL. This section presents some of the alternatives. 

### Cross-entropy Method (CEM) 

@Szita2006

### Evolutionary Search (ES)

@Salimans2017

Explanations from OpenAI: <https://blog.openai.com/evolution-strategies/>

Deep neuroevolution at Uber: <https://eng.uber.com/deep-neuroevolution/>



<!--PAGEBREAK-->


# Deep RL in practice

## Limitations

Excellent blog post from Alex Irpan on the limitations of deep RL: <https://www.alexirpan.com/2018/02/14/rl-hard.html>

## Reward shaping

Hindsight experience replay: @Andrychowicz2017 

## Simulation environments

Standard RL environments are needed to better compare the performance of RL algoritms. Below is a list of the most popular ones.

* OpenAI Gym <https://gym.openai.com>: a standard toolkit for comparing RL algorithms provided by the OpenAI fundation. It provides many environments, from the classical toy problems in RL (GridWorld, pole-balancing) to more advanced problems (Mujoco simulated robots, Atari games, Minecraft...). The main advantage is the simplicity of the interface: the user only needs to select which task he wants to solve, and a simple for loop allows to perform actions and observe their consequences:

```python
import gym
env = gym.make("Taxi-v1")
observation = env.reset()
for _ in range(1000):
    env.render()
    action = env.action_space.sample()
    observation, reward, done, info = env.step(action)
```

* OpenAI Universe <https://universe.openai.com>: a similar framework from OpenAI, but to control realistic video games (GTA V, etc).

* Darts environment <https://github.com/DartEnv/dart-env>: a fork of gym to use the Darts simulator instead of Mujoco. 

* Roboschool <https://github.com/openai/roboschool>: another alternative to Mujoco for continuous robotic control, this time from openAI.

* NIPS 2017 musculoskettal challenge <https://github.com/stanfordnmbl/osim-rl>

## Algorithm implementations

State-of-the-art algorithms in deep RL are already implemented and freely available on the internet. Below is a preliminary list of the most popular ones. Most of them rely on tensorflow or keras for training the neural networks and interact directly with gym-like interfaces.

* `rl-code` <https://github.com/rlcode/reinforcement-learning>: many code samples for simple RL problems (GridWorld, Cartpole, Atari Games). The code samples are mostly for educational purpose (Policy Iteration, Value Iteration, Monte-Carlo, SARSA, Q-learning, REINFORCE, DQN, A2C, A3C).


* `keras-rl` <https://github.com/matthiasplappert/keras-rl>: many deep RL algorithms implemented directly in keras: DQN, DDQN, DDPG, Continuous DQN (CDQN or NAF), Cross-Entropy Method (CEM), Dueling DQN, Deep SARSA...

* `Coach` <https://github.com/NervanaSystems/coach> from Intel Nervana also provides many state-of-the-art algorithms: DQN, DDQN, Dueling DQN, Mixed Monte Carlo (MMC), Persistent Advantage Learning (PAL), Distributional Deep Q Network, Bootstrapped Deep Q Network, N-Step Q Learning, Neural Episodic Control (NEC), Normalized Advantage Functions (NAF), Policy Gradients (PG), A3C, DDPG, Proximal Policy Optimization (PPO), Clipped Proximal Policy Optimization, Direct Future Prediction (DFP)...

* `OpenAI Baselines` <https://github.com/openai/baselines> from OpenAI too: A2C, ACER, ACKTR, DDPG, DQN, PPO, TRPO...

* `rlkit` <https://github.com/vitchyr/rlkit> from Vitchyr Pong (PhD student at Berkeley) with in particular model-based algorithms (TDM @Pong2018).


<!--PAGEBREAK-->

# References
