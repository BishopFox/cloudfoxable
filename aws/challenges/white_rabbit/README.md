# White Rabbit

Contributed by: Joseph Barcia (Bishop Fox)
category: 'Assumed Breach: Developer'
description: 
  **Overview**

  - **Author:** Joseph Barcia (Bishop Fox)
  - **Default state:** Disabled
  - **Estimated Cost:** $5.00/month
  - **Starting Point:** `arn:aws:iam::ACCOUNT_ID:role/alice`

Requirements:
  - AWS cli w/ default profile configured for Cloudfoxable
  - Docker installed and configured

  **Challenge Details**

  In Lewis Carroll's Alice's Adventures in Wonderland, the "rabbit hole" is the literal entrance to Wonderland, which Alice falls down after chasing the White Rabbit. This fall leads her to a bizarre and surreal world where the laws of physics and logic don't apply.

  In total, there are three flags designated as Flag1, Flag2, and Flag3. Can you find and read them all? Be careful of the false positives and the rabbit holes. Have fun exploiting and hopefully you learn something new. 
  
  It's no use going back to yesterday, because I was a different person then.

  Example Flag: '{FLAG:white_rabbit::FLAG1_FLAG2_FLAG3}'

  **Cleanup Tasks**

  Manually delete any additional resources you have created then execute the following: 

  ```
  bash cloudfoxable/aws/challenges/white_rabbit/cleanup.sh [profile] [region]

  ie.
  bash cloudfoxable/aws/challenges/white_rabbit/cleanup.sh default us-west-2
  ```

Value: 400

hints:
- "The hurrier I go, the behinder I get"
- "It's a poor sort of memory that only works backward"
- "I think you might do something better with the time than waste it in asking riddles that have no answers."
